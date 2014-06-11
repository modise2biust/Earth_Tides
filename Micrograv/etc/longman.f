c
c    convert meter rdg to mgals
c    calculate times (gmt and time in days (gmt) since 12 noon
c      dec. 31, 1899)
c      year = year + 1900
c      call dayr(month, day, year, ida)
c
c    calc tidal correction, apply tidal corr to gmr
c    note east longitude is negative, west positive for tideg
c
c      call timc(hgmt, time, ida, year, tgmt, et)
c      if (ie .eq. morf) etid = e / .3048
c      seclat = ((ltd * 60.) + sign(ltm,ltd)) * 60.
c      seclon = (((lnd * 60.) + sign(lnm,lnd)) * 60.) * (-1.0)
c      call tideg(seclat, seclon, etid, year, ida, tgmt, tidee)
c      gmr = gmr + tidee

      subroutine tideg(latsec, longsc, elev, year, ida, tgmt, tidee)
c  **  ref: jgr,64,#12,p2351,1959.
c	latsec,longsc-latitude&longitude in seconds
c  **  longitude measured + to west,- to east,
c  **  range 0-180 degrees.
c	elev- elevation in feet
c	year- 4 digit integer year
c	ida- day of year (1-366)
c	tgmt- greenwich standard time (4 digit integer)
c	tidee- earth tide correction,mgals
c	
      implicit real*8 (o-z, a-h), integer (i-n)
      real*8 n, ii, lsun, lamda
      integer tgmt, year, day
      dimension ds(4), dp(4), dh(3), ps(4), dn(4)
      real longsc, latsec, tidee
      real elev
      data ds / 4.720023438334786d+00, 8.399709299532332d+03, 
     &4.406955783270416d-05, 3.296732560239086d-08 /
      data dp / 5.835124720906877d+00, 7.101800935662992d+01, 
     &1.805445068160927d-04, 2.181661351142696d-07 /
      data ps / 4.908229466864464d+00, 3.000526416797298d-02, 
     &7.902455899166507d-06, 5.817762968100108d-08 /
      data dn / 4.523588570267900d+00, 3.375715303394320d+01, 
     &3.674887600803287d-05, 3.878507587154933d-08 /
      data dh / 4.881627934044856d+00, 6.283319509908986d+02, 
     &5.279618520477778d-06 /
      data dcmeg / 0.91739374d0 /
      data dsmeg / 0.39798093d0 /
      data dcii / 0.99597102d0 /
      data dsii / .089676321d0 /
      omega = 0.409315d0
      ii = 0.089797d0
      rad = 0.017453292519943d0
      deg = dble(longsc) / 3600.d0
      lamda = (dble(latsec) / 3.6d+03) * rad
      day = ida - 1
      call ju(year, day, tgmt, ieer, t)
c compute intermediate variables s,p,h
      if (ieer .ne. 0) goto 10
      h = (dh(1) + (dh(2) * t)) + (dh(3) * (t ** 2))
      s = ((ds(1) + (ds(2) * t)) + (ds(3) * (t ** 2))) + (ds(4) * (t ** 
     &3))
c compute sigma---mean longitude od moon reckoned from ascending
c      intersection of moon orbit with equator
      p = ((dp(1) + (dp(2) * t)) - (dp(3) * (t ** 2))) - (dp(4) * (t ** 
     &3))
      n = ((dn(1) - (dn(2) * t)) + (dn(3) * (t ** 2))) + (dn(4) * (t ** 
     &3))
      cosi = (dcmeg * dcii) - ((dsmeg * dsii) * dcos(n))
      sini = dsqrt(1.0d0 - (cosi ** 2))
      tani = datan2(sini,cosi)
      vs = (dsii * dsin(n)) / dsin(tani)
      vo2 = dsqrt(1.0d0 - (vs ** 2))
      v = datan2(vs,vo2)
      vc = vo2
      calpha = (dcos(n) * vc) + ((dsin(n) * vs) * dcmeg)
      salpha = (dsmeg * dsin(n)) / dsin(tani)
      alpha = 2.0d0 * datan(salpha / (1.d0 + calpha))
c compute chi----right ascension of meridian of point reckoned
c      from ascending moon-equator intersection
      sigma = (s + alpha) - n
      i = mod(tgmt,100)
      j = (tgmt - i) / 100
      xgmt = dble(j) + (dble(i) / 60.0d0)
      thran = ((15.0d0 * (xgmt - 12.0d0)) - deg) * rad
c compute xll----longitude of moon in its orbit from ascending
c      intersection with equator
c           eccentricity = 0.05490
c      ratio of sun/moon motion = 0.074804
      chi = (thran + h) - v
      xll1 = (sigma + (0.1098d0 * dsin(s - p))) + (0.003768d0 * dsin(
     &2.d0 * (s - p)))
      xll2 = (0.015400d0 * dsin((s - (2.0d0 * h)) + p)) + (0.0076940d0
     & * dsin(2.d0 * (s - h)))
c compute costh---zenith angle of moon
      xll = xll1 + xll2
      hcosi = dsqrt((1.d0 + cosi) / 2.d0)
      hsini = dsqrt((1.d0 - cosi) / 2.d0)
      bb = ((hcosi ** 2) * dcos(xll - chi)) + ((hsini ** 2) * dcos(xll
     & + chi))
c compute dd----distance between centers of the moon and earth
      costh = ((dsin(lamda) * sini) * dsin(xll)) + (dcos(lamda) * bb)
      rdd1 = 2.60144d-11 + (1.4325d-12 * dcos(s - p))
      rdd2 = 7.86439d-14 * dcos(2.d0 * (s - p))
      rdd3 = 2.0092d-13 * dcos((s - (2.d0 * h)) + p)
      rdd4 = 1.46008d-13 * dcos(2.d0 * (s - h))
      rdd = ((rdd1 + rdd2) + rdd3) + rdd4
c compute rr----radius of the earth at p
      dd = 1.d0 / rdd
      ci = 1.d0 / (1.0d0 + (6.738d-03 * (dsin(lamda) ** 2)))
      radius = (dsqrt(ci) * 6.37827d+08) + dble(elev * 30.48)
      gmoon1 = ((4.9049d+18 * radius) / (dd ** 3)) * ((3.0d0 * (costh
     & ** 2)) - 1.0d0)
      gmoon2 = ((7.3574d+18 / (dd ** 2)) * ((radius ** 2) / (dd ** 2)))
     & * ((5.0d0 * (costh ** 3)) - (3.0d0 * costh))
      gmoon = gmoon1 + gmoon2
      psun = ((ps(1) + (ps(2) * t)) + (ps(3) * (t ** 2))) + (ps(4) * (t
     & ** 3))
      esun = (0.01675104d0 - (0.0000418d0 * t)) - (0.000000126d0 * (t
     & ** 2))
      lsun = h + ((2.0d0 * esun) * dsin(h - psun))
      chisun = thran + h
      ocos2 = dcos(omega / 2.0d0)
      osin2 = dsin(omega / 2.0d0)
      cc = ((ocos2 ** 2) * dcos(lsun - chisun)) + ((osin2 ** 2) * dcos(
     &lsun + chisun))
c compute d---distance between earth and sun
      cosphi = ((dsin(lamda) * dsmeg) * dsin(lsun)) + (dcos(lamda) * cc)
      asun = 1.d0 / (1.495d+13 * (1.d0 - (esun ** 2)))
      sdd = 6.68896d-14 + ((asun * esun) * dcos(h - psun))
      dsun = 1.d0 / sdd
      sff = (3.0d0 * (cosphi ** 2)) - 1.0d0
      gsun = ((1.329d+26 / (dsun ** 2)) * (radius / dsun)) * sff
      tidee = (sngl(gsun + gmoon) / 1.e-03) * 1.2
   10 return 
      end

      subroutine timc(hrgmt, time, day, year, tgmt, et)
      real*8 et, dhrs, dyrs
c    calculates greenwich mean civil time tgmt
c    (add hrgmt to time, and changes day, year if necess.),
c    then converts tgmt to elapsed time et in days
c    since 12 noon 31 dec. 1899.
c    hrgmt - integer hrs (+ or -) to add to get gmt time -
c    time on 24 hour clock (4 digits)
c    day - day of year (1 - 365)
c    year - (4 digits)
c    gettings, oct. 1974.
      integer hrgmt, time, year, tgmt, day, hrs
      min = mod(time,100)
      hrs = (time - min) / 100
      tgmt = hrs + hrgmt
      if (tgmt) 10, 20, 20
   10 day = day - 1
      tgmt = 24 + tgmt
      goto 30
   20 if (tgmt - 24) 30, 25, 25
   25 day = day + 1
      tgmt = tgmt - 24
   30 tgmt = (tgmt * 100) + min
      if (day) 35, 35, 40
   35 day = 365
      year = year - 1
   40 if (day - 365) 45, 45, 42
   42 day = 1
      year = year + 1
c    now calc. elapsed time since 12 noon 31 dec. 1899
   45 continue
      hrs = (tgmt - min) / 100
      n = year - 1900
      dhrs = ((dble((hrs * 60) + min) * 60.) / 8.64d4) + 0.5
      dyrs = dble(((day - 1) + ((n - 1) / 4)) + (n * 365))
      et = dhrs + dyrs
      return 
      end
c  **  calculates day of year from month,day of month.
      subroutine dayr(month, iday, iyr, idyr)
  201 goto (202, 203, 204, 205, 206, 207, 208, 209, 210, 211, 212, 213
     &), month
  202 idate = iday
      goto 214
  203 idate = iday + 31
      goto 214
  204 idate = iday + 59
      goto 214
  205 idate = iday + 90
      goto 214
  206 idate = iday + 120
      goto 214
  207 idate = iday + 151
      goto 214
  208 idate = iday + 181
      goto 214
  209 idate = iday + 212
      goto 214
  210 idate = iday + 243
      goto 214
  211 idate = iday + 273
      goto 214
  212 idate = iday + 304
      goto 214
  213 idate = iday + 334
  214 if (((iyr / 4) * 4) .lt. iyr) goto 225
      if (month - 3) 225, 221, 221
  221 idate = idate + 1
  225 idyr = idate
      return 
      end

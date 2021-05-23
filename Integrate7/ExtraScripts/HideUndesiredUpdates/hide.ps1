<#
.notes 
  * original author mark berry (c) 2015 mcb systems all rights reserved free for personal or commercial use may not be sold
#>
$kbnumbers=971033,2952664,3021917,3068708,3080149,3172605,3184143,3150513,2902907,3140479,4493132,4524752,4519972,4520406,2676562
$x=0
try {
  $updatesession = new-object -comobject microsoft.update.session
  $updatesearcher = $updatesession.createupdatesearcher()
  $updatesearcher.includepotentiallysupersededupdates = $true
  $searchresult = $updatesearcher.search("isinstalled=0")
  foreach ($kbnumber in $kbnumbers) {
    [boolean]$kblisted = $false
    foreach ($update in $searchresult.updates) {
      foreach ($kbarticleid in $update.kbarticleids) {
        if ($kbarticleid -eq $kbnumber) {
          $kblisted = $true
          if ($update.ishidden -eq $false) {
            $x=1
            " - hide kb$kbnumber"
            $update.ishidden = $true     
          }
        }
      }
    }
  }
}
catch {
}
if ($x -eq 0) {
  " - no updates required to be hidden"
}
$objautoupdatesettings = (new-object -comobject "microsoft.update.autoupdate").settings
$objsysinfo = new-object -comobject "microsoft.update.systeminfo"
if ($objSysInfo.RebootRequired) {
  " - a reboot is required to complete some operations"
}

# Create new Mailuser for using Native tools to migrate mailboxes between tenants.
# Mail user object used as "destination" object onto which the source mailbox is copied/attached

#Set Variables
$clearpassword=""
$LicenseCode="TENANTNAME:LICENSE NAME" # get-msoluser -userprincipalname "LicensedUserUPN" | SELECT-object Licenses
$usagelocation="GB" #Country code for license usage
#Details from source mailbox object (i.e. get-recipient "NAME" | select name, archiveguid, exchangeguid, legacyexchangeDN)
$ExchangeGUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$ArchiveGUID="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$LegacyExchangeDN="/o=ExchangeLabs/ou=Exchange Administrative Group (XXXXXXXX)/cn=Recipients/cn=xxxxxxxxxxxx-aaaB"

$arguments= @{
firstname="Firstname"
lastname="LastName"
externalemailaddress="sourceemail"
primarysmtpaddress="temp_email@tenant.onmicrosoft.com"
}

try {
    $securepassword=$(ConvertTo-SecureString -String $clearpassword -AsPlainText -Force)

    $arguments.add("displayname","$($arguments.firstname) $($arguments.lastname)")
    $arguments.add("name","$($arguments.firstname) $($arguments.lastname)")
    $arguments.add("alias",$($arguments.firstname)+"."+$($arguments.lastname))
    $arguments.add("MicrosoftOnlineServicesID",$arguments.primarysmtpaddress)
    $arguments.add("Password",$securepassword)
    write-host "Creating account for $($arguments.externalemailaddress)" -ForegroundColor Yellow
    $MailUser=new-mailuser @arguments

    sleep -seconds 60

    $x500address="X500:$LegacyExchangeDN"

    write-host "Setting source Exchange object properties" 
    $mailuser | set-mailuser -ExchangeGuid $ExchangeGUID
    if ($archiveguiD -ne "") {
        $mailuser | set-mailuser -ArchiveGuid $ArchiveGUID
    }
    write-host "Setting x500 address to source exchange DN"
    $mailuser | set-mailuser -EmailAddresses @{add=$x500address}

    write-host "Applying license to account"
    $msoluser=get-msoluser -UserPrincipalName $MailUser.UserPrincipalName 
    $msoluser | set-msoluser -UsageLocation $usagelocation 
    $msoluser | Set-MsolUserLicense -AddLicenses $LicenseCode 
    write-host "Processing $($arguments.externalemailaddress) complete"  -ForegroundColor Yellow
}
catch
{
    Write-Host "An error occurred" -ForegroundColor Red
}

 <# param(
    [Parameter(Mandatory=$true)][string]$senseServerUrl,
    [Parameter(Mandatory=$true)][string]$senseVirtualProxy,
    [Parameter(Mandatory=$true)][string]$virtualProxyHeader,
    [Parameter(Mandatory=$true)][string]$userId,
    [Parameter(Mandatory=$true)][string]$certFriendlyName
    )
    #>

<# Hardcoded Parameters to make things move faster when testing
 request parameters in command line can be uncommented above and then
 comment below #>
$senseServerUrl = "https://sense20.112adams.local"
$senseVirtualProxy = "sdkheader"
$virtualProxyHeader = "hdr-sense-sdkheader"
$userId = "administrator"
$certFriendlyName = "sense20.112adams.local"

#Find Certificate
$ns = "System.Security.Cryptography.X509Certificates"
$store = New-Object "$ns.X509Store"("My","LocalMachine")

$store.Open("ReadOnly")

ForEach($cert in $store.Certificates)
{
    if($cert.FriendlyName -eq $certFriendlyName)
    {
        $certToUse = $cert
    }
}


# cross site scripting key
$xrfKey = "ABCDEFG123456789"

# Create a dictionary object that allows header storage in Rest call
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("X-Qlik-Xrfkey",$xrfKey)
$headers.Add($virtualProxyHeader, $userId)
$headers.Add("Content-Type","application/json")

# here is the path and filter used in the Rest call
$path = "/selection/user?xrfkey=$xrfKey"
$filter = "&filter=@KeepUser ne 'keep'"

# build the request string
$theCommand = $senseServerUrl + "/" + $senseVirtualProxy +"/qrs" + $path + $filter
Write-Host $theCommand

# this call returns the selection guid for the collection of users without the KeepUser property set.
$response = Invoke-RestMethod $theCommand -Headers $headers -Method Post -Certificate $certToUse

# build the request string to reference the user selection guid
$theCommand = $senseServerUrl + "/" + $senseVirtualProxy + "/qrs/selection/" + $response[0].id + "/user?xrfKey=" + $xrfKey

# this call deletes the users from the repository
$response = Invoke-RestMethod $theCommand -Headers $headers -Method Delete -Certificate $certToUse


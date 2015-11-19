function Delete-QlikUsers {
    <#
    .SYNOPSIS
    Deletes unwanted users from a Qlik Sense deployment.  
    .DESCRIPTION
    Requires a custom property named KeepUser set to user resources with a value of keep.
    
    Users header authentication virtual proxy to process authentication.

    Uses the supplied certificate based on friendly name.  Certificate needs to be in the Local Computer\Personal certificate store.
    .EXAMPLE
    Delete-QlikUsers %senseServerHostName% %senseVirtualProxyPrefix% %virtualProxyHeaderName% %userId% %certFriendlyName%
    .EXAMPLE
    Delete-QlikUsers sense20.112adams.local sdkheader hdr-sense-sdkheader administrator sense20.112adams.local
    .PARAMETER senseServerHostName
    The hostname for the Qlik Sense server
    .PARAMETER senseVirtualProxy
    The virtual proxy prefix for header authentication
    .PARAMETER virtualProxyHeader
    The header name used to store the userid sent to Qlik Sense server
    .PARAMETER userId
    The userId for the user to connect to QRS API
    .PARAMETER certFriendlyName
    The friendly name of the certificate used to connect to the Qlik Sense server 
    #>



    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)][string]$senseServerHostName,
        [Parameter(Mandatory=$true)][string]$senseVirtualProxy,
        [Parameter(Mandatory=$true)][string]$virtualProxyHeader,
        [Parameter(Mandatory=$true)][string]$userId,
        [Parameter(Mandatory=$true)][string]$certFriendlyName
        )

    <# Hardcoded Parameters to make things move faster when testing
    request parameters in command line can be uncommented above and then
    comment below 
    $senseServerHostName = "https://%senseServerHostName%"
    $senseVirtualProxy = "%VirtualProxyPrefix%"
    $virtualProxyHeader = "%HeaderName%"
    $userId = "%Admin User%"
    $certFriendlyName = "%certFriendlyName%"

    #>

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

    $protocol = "https://"
    $senseServerHostName = $protocol + $senseServerHostName

    function QRSConnect {

        param (
            [Parameter(Position=0,Mandatory=$true)]
            [string] $command,
            [Parameter(Position=1,Mandatory=$true)]
            [System.Collections.Generic.Dictionary`2[System.String,System.String]] $header,
            [Parameter(Position=2,Mandatory=$true)]
            [string] $method,
            [Parameter(Position=3,Mandatory=$true)]
            [System.Object] $cert,
            [Parameter(Position=4,Mandatory=$false)]
            [System.Object] $body
            )

        

        if($method -eq "POST")
        {
            $response = Invoke-RestMethod $command -Headers $header -Method $method -Certificate $cert -Body $body
        }
        else
        {
            $response = Invoke-RestMethod $command -Headers $header -Method $method -Certificate $cert
        }

        return $response
    }

    # cross site scripting key
    $xrfKey = "ABCDEFG123456789"

    # Create a dictionary object that allows header storage in Rest call
    $headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
    $headers.Add("X-Qlik-Xrfkey",$xrfKey)
    $headers.Add($virtualProxyHeader, $userId)
    $headers.Add("Content-Type","application/json")

    

    $filter = "&filter=@KeepUser ne 'keep'"
    

    #Get a count of the users without the KeepUser custom property set
    $path = "/user/count?xrfkey=$xrfkey"
    $theCommand = $senseServerHostName + "/" + $senseVirtualProxy + "/qrs" + $path + $filter

    $totalCount = QRSConnect $theCommand $headers "GET" $certToUse
    Write-Host $totalCount[0].value


    $count = 0



    $maxEntries = $totalCount[0].value/10
    Write-Host $maxEntries

    Write-Host "I'm going to run through this for loop $maxEntries times"

    for($i=0; $i -lt $maxEntries;$i++)
    {
        Write-Host "Run $i of $maxEntries"
        $path = "/user/table?xrfkey=$xrfkey"
        $jsonBody = "{
            'id':'00000000-0000-0000-0000-000000000000',
            'columns':
                [
                    {
                        'name':'id',
                        'columntype':'property',
                        'definition':'id'
                    }
                ]
        }"

        $addParams = "&skip=0&take=10&sortcolumn=id&orderAscending=true"
        $theCommand = $senseServerHostName + "/" + $senseVirtualProxy + "/qrs" + $path + $filter + $addParams
        $listOfIds = QRSConnect $theCommand $headers "POST" $certToUse $jsonBody
        Write-Host $listOfIds

        Write-Host "********************************"
        
        ForEach($row in $listOfIds[0].rows)
        {
            Write-Host "Deleting $row "
            $path = "/user/$row" + "?xrfkey=$xrfkey"
            write-host $path
            $theCommand = $senseServerHostName + "/" + $senseVirtualProxy + "/qrs" + $path
            QRSConnect $theCommand $headers "DELETE" $certToUse

        }
        Write-Host "********************************"
       
    }
}
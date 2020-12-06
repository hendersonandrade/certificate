# Script copied from  ØYVIND KALLSTAD
# Thank you ØYVIND KALLSTAD, this script is extremely useful to me
# https://communary.net/2017/08/16/retrieve-ssl-certificate-information/


function Get-CertInfoHttp {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [string] $URL,

        [Parameter()]
        [switch] $ReturnCertificate
    )

    try {
        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        $webRequest = [System.Net.HttpWebRequest]::Create($URL)

        $webRequest.KeepAlive = $false
        $webRequest.Timeout = 5000
        $webRequest.ServicePoint.ConnectionLeaseTimeout = 5000
        $webRequest.ServicePoint.MaxIdleTime = 5000

        #$null = $webRequest.GetResponse()
        $null = $webRequest.GetResponse().Dispose()
        
    }
    catch [System.Net.WebException] {
        if ($_.Exception.Status -eq [System.Net.WebExceptionStatus]::TrustFailure) {
            # We ignore trust failures, since we only want the certificate, and the service point is still populated at this point
        }
        else
        {
            Write-Warning $_.Exception.Message
        }
    }
    catch {
        Write-Warning $_.Exception.Message
    }

    if (($webRequest.ServicePoint.Certificate) -and ($webRequest.ServicePoint.Certificate.Handle -ne 0)) {
        if ($ReturnCertificate) {
            Write-Output $webRequest.ServicePoint.Certificate
        }
        else {
            Write-Output ([PSCustomObject] [Ordered] @{
                IssuerCN = $webRequest.ServicePoint.Certificate.Issuer.Split(', ',[System.StringSplitOptions]::RemoveEmptyEntries)[0].Split('=')[1]
                SubjectCN = $webRequest.ServicePoint.Certificate.Subject.Split(', ',[System.StringSplitOptions]::RemoveEmptyEntries)[0].Split('=')[1]
                ValidFrom = $webRequest.ServicePoint.Certificate.GetEffectiveDateString()
                ValidTo = $webRequest.ServicePoint.Certificate.GetExpirationDateString()
            })
        }

        $webRequest.ServicePoint.Certificate.Dispose()
    }   

    [Net.ServicePointManager]::ServerCertificateValidationCallback = $null
}

Get-CertInfoHttp -URL https://www.google.com.br -ReturnCertificate
# Script copied from  ØYVIND KALLSTAD
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

function Get-CertInfoTcp {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory)]
        [string] $ComputerName,

        [Parameter(Position = 1)]
        [int] $Port = 443,

        [Parameter()]
        [int] $Timeout = 3000,

        [Parameter()]
        [switch] $ReturnCertificate
    )
    try {

        $tcpClient = New-Object -TypeName System.Net.Sockets.TcpClient
        $iar = $tcpClient.BeginConnect($ComputerName,$Port,$null,$null)
        $wait = $iar.AsyncWaitHandle.WaitOne($Timeout,$false)
        if (!$wait) {
            $tcpClient.Close()
            Write-Warning 'Connection attempt timed out'
        }
        else {
            $null = $tcpClient.EndConnect($iar)

            if ($tcpClient.Connected) {
                $tcpStream = $tcpClient.GetStream()
                $sslStream = New-Object -TypeName System.Net.Security.SslStream -ArgumentList ($tcpStream, $false)
                $sslStream.AuthenticateAsClient($ComputerName)
                $certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList ($sslStream.RemoteCertificate)

                if ($ReturnCertificate) {
                    Write-Output $certificate

                }
                else {
                    Write-Output ([PSCustomObject] [Ordered] @{
                        IssuerCN = $certificate.Issuer.Split(', ',[System.StringSplitOptions]::RemoveEmptyEntries)[0].Split('=')[1]
                        SubjectCN = $certificate.Subject.Split(', ',[System.StringSplitOptions]::RemoveEmptyEntries)[0].Split('=')[1]
                        ValidFrom = $certificate.NotBefore
                        ValidTo = $certificate.NotAfter
                    })
                }

                $certificate.Dispose()
                $sslStream.Close()
                $sslStream.Dispose()
                $tcpStream.Close()
                $tcpStream.Dispose()
            }
            else {
                Write-Warning "Unable to establish connection to $ComputerName on port $Port"
            }

            $tcpClient.Close()
        }
    }
    catch {
        Write-Warning $_.Exception.InnerException.Message
    }
}

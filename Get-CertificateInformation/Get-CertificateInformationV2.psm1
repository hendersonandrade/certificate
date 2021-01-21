function Get-CertInfoWeb {
    [CmdletBinding()]
    param (
        [string[]] $URLs
    )

        [Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}
        
        foreach($URL in $URLs) {
            
            $WebRequest=[System.Net.HttpWebRequest]::Create($URL)
            try
            {
                $WebRequest.GetResponse().Dispose()
            }
            catch [System.Net.WebException]
            {
                if ($_.Exception.Status -eq [System.Net.WebExceptionStatus]::TrustFailure)
                {
                    # Ignoring trust failures
                }
                else
                {
                    throw
                }       
     
            }
            
            $Certificate = $WebRequest.ServicePoint.Certificate
            $Date = Get-Date            
            #  $Validity = if($Certificate.GetExpirationDateString() -lt $Date){Write-Host "Expired" -BackgroundColor Red}else{Write-Host "Not Expired" -BackgroundColor Green}
            
            Write-Output ([PSCustomObject] [Ordered]  @{
                URL = $URL
                IssuerCN = $Certificate.GetIssuerName()
                SubjectCN = $Certificate.GetName()
                ValidFrom = $Certificate.GetEffectiveDateString()
                ValidTo = $Certificate.GetExpirationDateString()
                Type = $Certificate.GetFormat()
                SerialNumber = $Certificate.GetSerialNumberString()

            })
        
        }
        
        
    }
            
    
Get-CertInfoWeb -URLs https://www.google.com.br

          

   



   








function Get-CertInfoLocaMachine {


}


function Get-CertInfoCurrentUser {


}


function Get-CertInfoCurrentUser{

}


Export-ModuleMember -Function Get-CertInformation, Get-CertInfoLocaMachine, Get-CertInfoCurrentUser, Get-CertInforSocket



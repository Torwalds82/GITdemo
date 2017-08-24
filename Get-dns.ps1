 Param ([Parameter(Mandatory=$true)] 
 [string]$DNSlogPath) 
 
 
 $DNSClients = @() 
 
 
 
 
 Function ConvertTo-BinaryIP( [String]$IP ) {  
   
   $IPAddress = [Net.IPAddress]::Parse($IP)  
   
   Return [String]::Join('.',  
     $( $IPAddress.GetAddressBytes() | %{  
       [Convert]::ToString($_, 2).PadLeft(8, '0') } ))  
 }  
   
   
Function IsPrivateNetwork( [String]$IP)   
 {  
     If ($IP.Contains("/"))  
     {  
         $Temp = $IP.Split("/")  
         $IP = $Temp[0]  
     }  
     
     $BinaryIP = ConvertTo-BinaryIP $IP; $Private = $False  
     
     Switch -RegEx ($BinaryIP)  
     {  
         "^1111" { $Class = "E"; $SubnetBitMap = "1111" }  
         "^1110" { $Class = "D"; $SubnetBitMap = "1110" }  
         "^110"  { $Class = "C"  
                     If ($BinaryIP -Match "^11000000.10101000") { $Private = $True }   
                 }  
         "^10"   { $Class = "B"  
                     If ($BinaryIP -Match "^10101100.0001") { $Private = $True } }  
         "^0"    { $Class = "A"  
                     If ($BinaryIP -Match "^00001010") { $Private = $True }   
                 }  
     }     
     return $Private  
 }  

 
Get-Content $DNSlogPath | where {$_ -match "Rcv " -and ($_ -match " Q " -or $_ -match " R Q ")} | foreach { 
    $ClientIP = ($_ -split(" "))[8] 
 
 
if (IsPrivateNetwork($ClientIP) -eq $true) 
 { 
 
 
    $DNSClients += New-Object psobject -Property @{ 
      ClientIP = $ClientIP 
 
 
 } 
    }  
 }  
 
 
 $DNSClients | Group-Object -Property ClientIP -NoElement | Sort-Object Count -Descending  | ` 
 select count, @{Name="IP";Expression={$_.name}} | export-csv -nti ./DNSClients.csv 

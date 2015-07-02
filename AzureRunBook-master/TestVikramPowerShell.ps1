workflow DeployVMInAzure
{
  param(
  $azureSettingsFile,
  $azureAccountName,
  $imageName,
  $vmName,
  $instanceSize,
  $adminUserName,
  $adminPassword,
  $domain,
  $domainUserName,
  $domainPassword,
  $affinityGroup,
  $networkName,
  $azureStorageAccountName,
  $subnetName,
  $activityID,
  $smManagementServer
  )


  
  #Set Instance Size
  if ($instanceSize -eq "A0") { $instanceSize = 'ExtraSmall' }
  elseif ($instanceSize -eq "A1") { $instanceSize = 'Small' }
  elseif ($instanceSize -eq "A2") { $instanceSize = 'Medium' }
  elseif ($instanceSize -eq "A3") { $instanceSize = 'Large' }
  elseif ($instanceSize -eq "A4") { $instanceSize = 'ExtraLarge' }
   
  inlinescript
  {
    #Import Azure PowerShell Module
    Import-Module Azure

    #Remove Existing Azure Sessions
    Remove-AzureAccount -Name $Using:azureAccountName -Force
    
    #Import Azure Settings File
    Import-AzurePublishSettingsFile -PublishSettingsFile ($Using:azureSettingsFile).Replace("\\","\")
    
    #Set Azure Subscription
    Get-AzureSubscription | Set-AzureSubscription -currentstorageaccountname $Using:azureStorageAccountName
    
    #Increment VM Name
    $i = 0
    foreach ($vm in Get-AzureVM)
    {
      if ($vm.InstanceName.Contains($Using:vmName))
      {
        [int]$increment = $vm.InstanceName.SubString($Using:vmName.Length)
        if ($increment -gt $i) { $i = $increment }
      }
    }
    $i++
    $vmName = $Using:vmName + $i

    #Create New Azure Cloud Service
    New-AzureService -ServiceName $vmName -AffinityGroup $Using:affinityGroup

    #Create Azure VM
    if ($Using:domain)
    {
      New-AzureVMConfig -Name $vmName -InstanceSize $Using:instanceSize -ImageName $Using:imageName | 
      Add-AzureProvisioningConfig -WindowsDomain -Password $Using:adminPassword -JoinDomain $Using:domain -Domain $Using:domain -DomainUserName $Using:domainUserName -DomainPassword $Using:domainPassword -AdminUsername $Using:adminUserName | 
      Set-AzureSubnet $Using:subnetName |
      New-AzureVM -ServiceName $vmName -VNetName $Using:networkName
    }
    else
    {
      New-AzureVMConfig -Name $vmName -InstanceSize $Using:instanceSize -ImageName $Using:imageName | 
      Add-AzureProvisioningConfig -Windows -AdminUsername $Using:adminUserName -Password $Using:adminPassword | 
      Set-AzureSubnet $Using:subnetName |
      New-AzureVM -ServiceName $vmName -VNetName $Using:networkName
    }

    #Set SM Activity to Completed
    if ($Using:activityID)
    {
      #Connect to SM
      $smDir = (Get-ItemProperty 'hklm:/software/microsoft/System Center/2010/Service Manager/Setup').InstallDirectory
      Import-Module ($smDir + "\Powershell\System.Center.Service.Manager.psd1")
      $sm = New-SCManagementGroupConnection -computerName $Using:smManagementServer

      #Get SM Class
      $class = Get-SCClass -name 'Custom.Example.Azure.DeployVM'

      #Get SM Class Instance
      $instance = Get-SCClassInstance -class $class -filter ('Id -eq {0}' -f $Using:activityID)

      #Update Activity to Completed
      $instance.Status = "ActivityStatusEnum.Completed"
      Update-SCSMClassInstance -Instance $instance
    }
  }
}
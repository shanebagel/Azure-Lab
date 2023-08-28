

function Intialize-CloudDeployment {

<#
.SYNOPSIS
Initializes an azure environment, including a vNet, Virtual Machines, storage account, and various other Azure services

.DESCRIPTION
Script configures a full azure lab environment
Provisions a vNet, 4 VMs, key vault, automation account, NSG (exists at subnet-level), and storage account

Creates 1 automation account - ShaneAA
Creates 1 key vault - ShaneHKV
Creates 1 windows DC server - roles DNS, RSAT
Creates 1 windows server for SQL - roles SQL, and SSMS
Creates 1 linux server - ShaneLX
Creates 1 linux server - ShaneLX2
Creates 1 resource group - ShaneRG
Creates 1 virtual network and 1 virtual subnet - ShaneVNET
Creates 1 NSG to control inbound and outbound traffic - Scoped at the Subnet-level
Creates 1 storage account - ShaneSTO

.PARAMETER Credential
Specifies a credential object, this is the credential that is set on each VM that is provisioned

.EXAMPLE
Create core deployment
Initialize-CloudDeployment -Credential $Credential

.EXAMPLE
Create VM
Initialize-ShaneSVR

.NOTES
Run each function individually

# ShaneSVR - Web server, domain controller, DNS, FTP. ad.smhcomputers.com for domain - AD connect runs from, remove AD connect from local lab
# ShaneSQL - Database Server, file server
# ShaneLX - Linux server 
# ShaneLX2 - Secondary Linux server

#>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $True)]
        [ValidateNotNull()]
        [pscredential]$Credential
    )

    # Must be ran from azure cloud shell 

    # Create Resource Group
    New-AzResourceGroup -Name $ResourceGroup -Location $Location

    # Create Automation Account
    New-AzAutomationAccount -Name "ShaneAA" -ResourceGroupName $ResourceGroup -Location $Location -Plan "Free"

    # Create Key Vault
    New-AzKeyVault -VaultName "ShaneKV" -ResourceGroupName $ResourceGroup -Location $Location

    # Create subnet
    $Subnet = New-AzVirtualNetworkSubnetConfig -Name ShaneSUB -AddressPrefix "10.0.0.0/24"

    # Create VNet
    New-AzVirtualNetwork -Name "ShaneVNET" -ResourceGroupName $ResourceGroup -Location $Location -AddressPrefix "10.0.0.0/16" -Subnet $Subnet

    # Create Storage Account
    New-AzStorageAccount -Name "ShaneSTO" -ResourceGroupName $ResourceGroup -Location $Location -SkuName "Standard_LRS"

    # Create Public IP
    New-AzPublicIPAddress -Name "ShanePubIP" -ResourceGroupName $ResourceGroup -AllocationMethod "Static" -Location $Location -Sku Basic 

    # Define Hostnames
    $VMs = (
        "ShaneSVR", "ShaneSQL", "ShaneLX", "ShaneLX2"
    )
    
    # Define Variables
    $RGName = "ShaneRG"
    $VnetName = "ShaneVNET"
    $Location = "East US"

    function Initialize-ShaneSVR {

        $VMName = $VMs[0]

        #We need all infos about the virtual network
        $VirtualNetwork = (Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RGName)

        #Create a network interface
        $nic = New-AzNetworkInterface `
            -ResourceGroupName $RGName `
            -Name "ShaneNIC1" `
            -Location $Location `
            -PrivateIpAddress "10.0.0.10" `
            -SubnetId $VirtualNetwork.Subnets[0].Id    

        #Define your VM
        $vmConfig = New-AzVMConfig -VMName $VMName -VMSize "Standard_B2ms"

        #Create the rest of your VM configuration
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
            -Windows `
            -ComputerName $VMName `
            -Credential $credential `
            -ProvisionVMAgent `
            -EnableAutoUpdate

        $vmConfig = Set-AzVMSourceImage -VM $vmConfig `
            -PublisherName "MicrosoftWindowsServer" `
            -Offer "WindowsServer" `
            -Skus "2022-Datacenter" `
            -Version "latest"

        $vmConfig = Set-AzVMOSDisk -VM $vmConfig `
            -StorageAccountType "Standard_LRS" `
            -Name "ShaneDisk1" `
            -DiskSizeInGB "128" `
            -CreateOption FromImage

        $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable

        #Attach the network interface that you previously created
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

        #Create your VM
        New-AzVM -VM $vmConfig -ResourceGroupName $RGName -Location $Location

    } # End function

    Initialize-ShaneSQL {

        $VMName = $VMs[1]
    
        #We need all infos about the virtual network
        $VirtualNetwork = (Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RGName)
    
        #Create a network interface
        $nic = New-AzNetworkInterface `
            -ResourceGroupName $RGName `
            -Name "ShaneNIC2" `
            -Location $Location `
            -PrivateIpAddress "10.0.0.20" `
            -SubnetId $VirtualNetwork.Subnets[0].Id    
    
        #Define your VM
        $vmConfig = New-AzVMConfig -VMName $VMName -VMSize "Standard_B2ms"
    
        #Create the rest of your VM configuration
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
            -Windows `
            -ComputerName $VMName `
            -Credential $credential `
            -ProvisionVMAgent `
            -EnableAutoUpdate
    
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig `
            -PublisherName "MicrosoftWindowsServer" `
            -Offer "WindowsServer" `
            -Skus "2022-Datacenter" `
            -Version "latest"
    
        $vmConfig = Set-AzVMOSDisk -VM $vmConfig `
            -StorageAccountType "Standard_LRS" `
            -Name "ShaneDisk2" `
            -DiskSizeInGB "128" `
            -CreateOption FromImage
    
        $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable
    
        #Attach the network interface that you previously created
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
    
        #Create your VM
        New-AzVM -VM $vmConfig -ResourceGroupName $RGName -Location $Location

    } # End function

    function Initialize-ShaneLX {

        $VMName = $VMs[2]
    
        #We need all infos about the virtual network
        $VirtualNetwork = (Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RGName)
    
        #Create a network interface
        $nic = New-AzNetworkInterface `
            -ResourceGroupName $RGName `
            -Name "ShaneNIC3" `
            -Location $Location `
            -PrivateIpAddress "10.0.0.30" `
            -SubnetId $VirtualNetwork.Subnets[0].Id    
    
        #Define your VM
        $vmConfig = New-AzVMConfig -VMName $VMName -VMSize "Standard_B2ms"
    
        #Create the rest of your VM configuration
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
            -Linux `
            -ComputerName $VMName `
            -Credential $credential
    
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig `
            -PublisherName "RedHat" `
            -Offer "RHEL" `
            -Skus "8-lvm-gen2" `
            -Version "latest"
    
        $vmConfig = Set-AzVMOSDisk -VM $vmConfig `
            -StorageAccountType "Standard_LRS" `
            -Name "ShaneDisk3" `
            -DiskSizeInGB "64" `
            -CreateOption FromImage
    
        $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable
    
        #Attach the network interface that you previously created
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
    
        #Create your VM
        New-AzVM -VM $vmConfig -ResourceGroupName $RGName -Location $Location

    } # End function

    function Initialize-ShaneLX2 {

        $VMName = $VMs[3]
        $credential = Get-Credential
    
        #We need all infos about the virtual network
        $VirtualNetwork = (Get-AzVirtualNetwork -Name $VnetName -ResourceGroupName $RGName)
    
        #Create a network interface
        $nic = New-AzNetworkInterface `
            -ResourceGroupName $RGName `
            -Name "ShaneNIC4" `
            -Location $Location `
            -PrivateIpAddress "10.0.0.40" `
            -SubnetId $VirtualNetwork.Subnets[0].Id    
    
        #Define your VM
        $vmConfig = New-AzVMConfig -VMName $VMName -VMSize "Standard_B2ms"
    
        #Create the rest of your VM configuration
        $vmConfig = Set-AzVMOperatingSystem -VM $vmConfig `
            -Linux `
            -ComputerName $VMName `
            -Credential $credential
    
        $vmConfig = Set-AzVMSourceImage -VM $vmConfig `
            -PublisherName "RedHat" `
            -Offer "RHEL" `
            -Skus "8-lvm-gen2" `
            -Version "latest"
    
        $vmConfig = Set-AzVMOSDisk -VM $vmConfig `
            -StorageAccountType "Standard_LRS" `
            -Name "ShaneDisk4" `
            -DiskSizeInGB "64" `
            -CreateOption FromImage
    
        $vmConfig = Set-AzVMBootDiagnostic -VM $vmConfig -Disable
    
        #Attach the network interface that you previously created
        $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
    
        #Create your VM
        New-AzVM -VM $vmConfig -ResourceGroupName $RGName -Location $Location
        
    } # End function

    # Create NSG and NSG rules
    $Rule = New-AzNetworkSecurityRuleConfig -Name "RDP-Rule" -Description "Allows RDP traffic" -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
    $Rule2 = New-AzNetworkSecurityRuleConfig -Name "HTTP-Rule" -Description "Allows HTTP traffic" -Access Allow -Protocol Tcp -Direction Inbound -Priority 101 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80
    $Rule3 = New-AzNetworkSecurityRuleConfig -Name "HTTPS-Rule" -Description "Allows HTTPS traffic" -Access Allow -Protocol Tcp -Direction Inbound -Priority 102 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
    $Rule4 = New-AzNetworkSecurityRuleConfig -Name "SSH-Rule" -Description "Allows SSH traffic" -Access Allow -Protocol Tcp -Direction Inbound -Priority 103 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22
    $Rule5 = New-AzNetworkSecurityRuleConfig -Name "DNS-Rule" -Description "Allows Port 53 traffic" -Access Allow -Protocol Udp -Direction Inbound -Priority 104 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 53
    New-AzNetworkSecurityGroup -Name "ShaneNSG" -ResourceGroup $ResourceGroup -Location $Location -SecurityRules $Rule, $Rule2, $Rule3, $Rule4, $Rule5

    # Update network security group property, and push update with Set-AzVirtualNetwork so NSG exists at subnet-level
    $Vnet = Get-AzVirtualNetwork -Name "ShaneVNET" -ResourceGroupName $ResourceGroup
    $Subnet = Get-AzVirtualNetworkSubnetConfig -VirtualNetwork $Vnet 
    $Nsg = Get-AzNetworkSecurityGroup -Name "ShaneNSG"
    $Subnet.NetworkSecurityGroup = $Nsg
    Set-AzVirtualNetwork -VirtualNetwork $Vnet

    # Set Public IP on NIC for ShaneSVR
    $Nic = Get-AzNetworkInterface -Name "ShaneNIC1" -ResourceGroupName $ResourceGroup
    $PubIP = Get-AzPublicIpAddress -Name "ShanePubIP" -ResourceGroupName $ResourceGroup
    $Nic | Set-AzNetworkInterfaceIpConfig -Name ipconfig1 -PublicIPAddress $PubIP -Subnet $Subnet
    $Nic | Set-AzNetworkInterface
    
    # Finish Rules   
    # Add-AzMetricAlertRuleV2 -Name "Machine has been online longer than 2 hours" -ResourceGroupName $ResourceGroup -WindowSize 0:5 -Frequency 0:5 -TargetResourceScope "/subscriptions/4837e608-9665-4f4e-9625-c7a126e8d363/resourceGroups/ShaneRG/providers/Microsoft.Compute/virtualMachines/ShaneSVR" -TargetResourceType "Microsoft.Compute/virtualMachines" -TargetResourceRegion "EastUS" -Severity 4 -Action $Action -Condition

    # On ShaneSVR - copy the configuration from Shaneserver on-prem, and do the same for the SQL server - copy config from shaneserver2
    # Setup the ShaneVM with everything documented in new computer setup

}
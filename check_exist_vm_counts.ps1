"##vso[task.setvariable variable=vm_exist_count]1"
"##vso[task.setvariable variable=vm_exist_ip]4"
$VM_exist_count = 0
$VM_exist_ip = 4
$VMs_Lenght = ((Get-AzVM -ResourceGroupName "rg-JackChan" -Name "vm-avd-lab*").Name).Length

Write-Host $VMs_Lenght

if ([int]$VMs_Lenght -eq $null) {
    "No value to change"
}
elseif ([int]$VMs_Lenght -lt 0) {
    "No value to change"
}
else {
    $VM_exist_count = $VM_exist_coun+ [int]$VMs_Lenght 
    "##vso[task.setvariable variable=vm_exist_count]$VM_exist_count"
    $VM_exist_ip = $VM_exist_ip + [int]$VMs_Lenght
    "##vso[task.setvariable variable=vm_exist_ip]$VM_exist_ip"
}



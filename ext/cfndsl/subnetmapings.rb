def nlb_subnet_mappings(resource_name, azs)
  if azs.to_i > 0
    resources = []
    azs.times do |az|
      resources << { SubnetId: Ref("#{resource_name}#{az}"), AllocationId: Ref("Nlb#{az}EIPAllocationId") }
    end
    if_statement = FnIf("#{azs-1}#{resource_name}", resources, nlb_subnet_mappings(resource_name, azs - 1)) if azs>1
    if_statement = { SubnetId: Ref("#{resource_name}#{azs}"), AllocationId: Ref("Nlb#{azs}EIPAllocationId") } if azs == 1
    if_statement
  else
    { SubnetId: Ref("#{resource_name}#{azs}"), AllocationId: Ref("Nlb#{azs}EIPAllocationId") }
  end
end

def nlb_eip_conditions(azs)
  azs.times { |az| Condition("Nlb#{az}EIPRequired", FnEquals(Ref("Nlb#{az}EIPAllocationId"), 'dynamic')) }
end

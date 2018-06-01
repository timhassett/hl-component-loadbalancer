HighlanderComponent do
  DependsOn 'vpc@1.0.4'
  Name 'loadbalancer'
  Parameters do
    StackParam 'EnvironmentName', 'dev', isGlobal: true
    StackParam 'EnvironmentType', 'development', isGlobal: true
    StackParam 'StackOctet', isGlobal: true
    ComponentParam 'DnsDomain' if defined?(records)
    ComponentParam 'SslCertId'
    subnet_parameters({'public'=>{'name'=>'Public'}}, maximum_availability_zones)
    subnet_parameters({'compute'=>{'name'=>'Compute'}}, maximum_availability_zones) if defined?(loadbalancer_scheme) && loadbalancer_scheme == 'internal'
    OutputParam component: 'vpc', name: "VPCId"
  end
end
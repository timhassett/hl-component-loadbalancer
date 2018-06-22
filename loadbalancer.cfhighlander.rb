CfhighlanderTemplate do
  DependsOn 'vpc@1.2.0'
  Name 'loadbalancer'
  Parameters do
    ComponentParam 'EnvironmentName', 'dev', isGlobal: true
    ComponentParam 'EnvironmentType', 'development', isGlobal: true
    ComponentParam 'StackOctet', isGlobal: true
    MappingParam('DnsDomain') do
      map 'AccountId'
      attribute 'DnsDomain'
    end
    MappingParam('SslCertId') do
      map 'AccountId'
      attribute 'SslCertId'
    end

    maximum_availability_zones.times do |x|
      private = false
      if defined?(loadbalancer_scheme) && loadbalancer_scheme == 'internal'
        private = true
      end
      ComponentParam "SubnetPublic#{x}" unless private
      ComponentParam "SubnetCompute#{x}" if private
    end

    ComponentParam 'VPCId', type: 'AWS::EC2::VPC::Id'
  end
end
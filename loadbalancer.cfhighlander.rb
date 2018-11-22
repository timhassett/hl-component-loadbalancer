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

    if defined?(listeners)
      listeners.each do |listener,properties|
        if properties['protocol'] == 'https'
          MappingParam('SslCertId') do
            map 'AccountId'
            attribute 'SslCertId'
          end
          properties['certificates'].each do |cert|
            ComponentParam "#{cert}CertificateArn"
          end if properties.has_key?('certificates')
        end
      end
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

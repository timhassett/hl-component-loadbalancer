CloudFormation do

  az_conditions_resources('SubnetPublic', maximum_availability_zones)

  EC2_SecurityGroup('SecurityGroupLoadBalancer') do
    GroupDescription FnJoin(' ', [ Ref('EnvironmentName'), component_name ])
    VpcId Ref('VPCId')
    SecurityGroupIngress sg_create_rules(securityGroups['loadbalancer'], ip_blocks)
  end

  atributes = []

  loadbalancer_attributes.each do |key,value|
    atributes << { Key: key, Value: value }
  end if loadbalancer_attributes.any?

  tags = []
  tags << { Key: "Environment", Value: Ref("EnvironmentName") }
  tags << { Key: "EnvironmentType", Value: Ref("EnvironmentType") }

  loadbalancer_tags.each do |key,value|
    tags << { Key: key, Value: value }
  end if loadbalancer_tags.any?

  ElasticLoadBalancingV2_LoadBalancer('LoadBalancer') do

    if loadbalancer_scheme == 'internal'
      Subnets az_conditional_resources('SubnetCompute', maximum_availability_zones)
      Scheme 'internal'
    else
      Subnets az_conditional_resources('SubnetPublic', maximum_availability_zones)
    end

    if loadbalancer_type == 'network'
      Type loadbalancer_type
    else
      SecurityGroups [ Ref('SecurityGroupLoadBalancer') ]
    end

    Tags tags if tags.any?
    LoadBalancerAttributes atributes if atributes.any?
  end

  targetgroups.each do |tg|

    atributes = []

    tg['atributes'].each do |key,value|
      atributes << { Key: key, Value: value }
    end if tg.has_key?('atributes')

    tags = []
    tags << { Key: "Environment", Value: Ref("EnvironmentName") }
    tags << { Key: "EnvironmentType", Value: Ref("EnvironmentType") }

    tg['tags'].each do |key,value|
      tags << { Key: key, Value: value }
    end if tg.has_key?('tags')

    ElasticLoadBalancingV2_TargetGroup("#{tg['name']}TargetGroup") do
      ## Required
      Port tg['port']
      Protocol tg['protocol'].upcase
      VpcId Ref('VPCId')
      ## Optional
      if tg.has_key?('healthcheck')
        HealthCheckPort tg['healthcheck']['port'] if tg['healthcheck'].has_key?('port')
        HealthCheckProtocol tg['healthcheck']['protocol'] if tg['healthcheck'].has_key?('port')
        HealthCheckIntervalSeconds tg['healthcheck']['interval'] if tg['healthcheck'].has_key?('interval')
        HealthCheckTimeoutSeconds tg['healthcheck']['timeout'] if tg['healthcheck'].has_key?('timeout')
        HealthyThresholdCount tg['healthcheck']['heathy_count'] if tg['healthcheck'].has_key?('heathy_count')
        UnhealthyThresholdCount tg['healthcheck']['unheathy_count'] if tg['healthcheck'].has_key?('unheathy_count')
        HealthCheckPath tg['healthcheck']['path'] if tg['healthcheck'].has_key?('path')
        Matcher ({ HttpCode: tg['healthcheck']['code'] }) if tg['healthcheck'].has_key?('code')
      end

      TargetType tg['type'] if tg.has_key?('type')
      TargetGroupAttributes atributes if atributes.any?

      Tags tags if tags.any?
    end

    Output("#{tg['name']}TargetGroup", Ref("#{tg['name']}TargetGroup"))
  end if defined?('targetgroups')

  listeners.each do |listener|
    ElasticLoadBalancingV2_Listener("#{listener['name']}Listener") do
      Protocol listener['protocol'].upcase
      Certificates [{CertificateArn: Ref('DefaultSslCertId')}] if listener['protocol'] == 'https'
      Port listener['port']
      DefaultActions ([
        TargetGroupArn: Ref("#{listener['default_targetgroup']}TargetGroup"),
        Type: "forward"
      ])
      LoadBalancerArn Ref('LoadBalancer')
    end
  end if defined?('listeners')

  if defined? records
    records.each do |record|
      Route53_RecordSet("#{record.gsub('*','Wildcard')}LoadBalancerRecord") do
        HostedZoneName FnJoin("", [ Ref("EnvironmentName"), ".", Ref('DnsDomain'), "." ])
        Name FnJoin("", [ "#{record}.", Ref("EnvironmentName"), ".", Ref('DnsDomain'), "." ])
        Type 'A'
        AliasTarget ({
          DNSName: FnGetAtt("LoadBalancer","DNSName"),
          HostedZoneId: FnGetAtt("LoadBalancer","CanonicalHostedZoneID")
        })
      end
    end 
  end

  Output('LoadBalancer', Ref('LoadBalancer'))
  Output('SecurityGroupLoadBalancer', Ref('SecurityGroupLoadBalancer'))

end
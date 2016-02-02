# encoding: utf-8

require 'json'
require 'aws-sdk'

module TemplateHelper
  class RegionMap
    def initialize(product_codes)
      @region_map = {}
      build_map(product_codes)
    end

    def to_json(options = nil)
      @region_map.to_json(options)
    end

    def to_hash
      @region_map
    end

    private

    def build_map(product_codes)
      Aws.config.update(region: 'us-east-1')
      ec2_cl = Aws::EC2::Client.new

      regions = ec2_cl.describe_regions.regions.map(&:region_name)

      regions.each do |region|
        ec2_client = Aws::EC2::Client.new(region: region)
        images = ec2_client.describe_images(
          filters: [
            { name: 'state', values: ['available'] },
            { name: 'product-code', values: product_codes.values }
          ]
        ).images
        if (images.size == 0)
          STDERR.puts "No images found for region '#{region}'"
          next
        end

        ami_map = {}
        product_codes.each do |name, code|
          filtered_images = images.select { |i| i.product_codes.any? { |pc| pc.product_code_id == code  } }
          sorted_images = filtered_images.sort_by(&:creation_date)
          ami_map[name] = sorted_images.last.image_id
        end

        @region_map[region] = ami_map
      end
  end
  end
end

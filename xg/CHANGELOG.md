# Sophos XG Firewall on AWS Release Notes

## Sophos XG Firewall v19.5.1.278 on AWS

This release includes all the features and fixes in v19.5 GA (v19.5.0.197).  

### AWS Firmware

See the [Sophos XG Firewall v19.5.1.278 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-v195-mr1-is-now-available).

### Template

Force use of IMDSv2 for all deployment topologies
Update CFT resource dependencies so AttachGateway is always created first
Make AgreeUserTerms parameter case insensitve


## Sophos XG Firewall v19.5.0.197 on AWS

This release includes all the features and fixes in v19.5 GA (v19.5.0.197).  

### AWS Firmware

See the [Sophos XG Firewall v19.5.0.197 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-v195-is-now-available).

### Template

Parameter validation provides better error messages

## Sophos XG Firewall v19.0.1.384 on AWS

This release includes all the features and fixes in v19.0 MR1 (v19.0.1.365).  
Autoscaling is also supported for EAP customers, please see the link below for details.

### AWS Firmware

See the [Sophos XG Firewall v19.0.1.365 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-v19-mr1-re_2d00_release-build-365-is-now-available).
See the [Autoscaling Sophos Firewall - EAP Announcement](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/autoscaling-sophos-firewall-on-aws---eap-coming-soon)

### Template

The standalone and ha_tgw templates have the following changes:
- PublicNetworkCIDR is now a configurable parameter 


## Sophos XG Firewall v19.0.0.317 on AWS

### AWS Firmware

See the [Sophos XG Firewall v19.0.0.317 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-os-v19-is-now-available).

### Template

The standalone template has the following changes:
- Create separate templates for each license type (standalone_byol and standalone_payg)
- Migrate the templates to YAML format


## Sophos XG Firewall v18.5.3.408 on AWS

### AWS Firmware

See the [Sophos XG Firewall v18.5.3.408 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-v18-5-mr3-is-now-available).

### Template

The standalone template has the following changes:
- The T2 instance type has been deprecated.  T3 is a direct replacement.
- Added support for SSMK password
- Added support for restoring configuration from S3 on launch

## Sophos XG Firewall v18.5.2.380 on AWS

### AWS Firmware

See the [Sophos XG Firewall v18.5.2.380 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-v18-5-mr2-is-now-available).

### Template

Standalone template is changed in this release to support Sophos Central registration. Additionally, supported instance types are updated. [Show diff](https://github.com/sophos-iaas/aws-cf-templates/compare/xg18.5.1.326..xg18.5.2.380)

## Sophos XG Firewall v18.5.1.326 on AWS

### AWS Firmware

See the [Sophos XG Firewall v18.5.1.326 release notes](https://community.sophos.com/sophos-xg-firewall/b/blog/posts/sophos-firewall-v18-5-mr1-is-now-available).

## Sophos XG Firewall v18.0.3.475 on AWS

### AWS Firmware

See the [Sophos XG Firewall v18.0.3.475 release notes](https://community.sophos.com/xg-firewall/b/blog/posts/xg-firewall-v18-mr3).

## Sophos XG Firewall v18.0.0.379 on AWS

### AWS Firmware

See the [Sophos XG Firewall v18.0.0.379 release notes](https://community.sophos.com/products/xg-firewall/b/blog/posts/xg-firewall-18-0-ga-build379-released).

## Sophos XG Firewall v18.0.0.339 on AWS

### AWS Firmware

See the [Sophos XG Firewall v18.0.0.339 release notes](https://community.sophos.com/products/xg-firewall/b/blog/posts/xg-firewall-v18-ga_2d00_build339-is-now-available).


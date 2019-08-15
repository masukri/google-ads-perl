#!/usr/bin/perl -w
#
# Copyright 2019, Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This example adds campaign targeting criteria. To get campaign targeting
# criteria, run get_campaign_targeting_criteria.pl.

use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Google::Ads::GoogleAds::GoogleAdsClient;
use Google::Ads::GoogleAds::Utils::GoogleAdsHelper;
use Google::Ads::GoogleAds::V1::Resources::CampaignCriterion;
use Google::Ads::GoogleAds::V1::Common::KeywordInfo;
use Google::Ads::GoogleAds::V1::Common::LocationInfo;
use Google::Ads::GoogleAds::V1::Common::ProximityInfo;
use Google::Ads::GoogleAds::V1::Common::AddressInfo;
use Google::Ads::GoogleAds::V1::Enums::KeywordMatchTypeEnum qw(BROAD);
use Google::Ads::GoogleAds::V1::Enums::ProximityRadiusUnitsEnum qw(MILES);
use
  Google::Ads::GoogleAds::V1::Services::CampaignCriterionService::CampaignCriterionOperation;
use Google::Ads::GoogleAds::V1::Utils::ResourceNames;

use Getopt::Long qw(:config auto_help);
use Pod::Usage;
use Cwd qw(abs_path);

# The following parameter(s) should be provided to run the example. You can
# either specify these by changing the INSERT_XXX_ID_HERE values below, or on
# the command line.
#
# Parameters passed on the command line will override any parameters set in
# code.
#
# Running the example with -h will print the command line usage.
my $customer_id = "INSERT_CUSTOMER_ID_HERE";
my $campaign_id = "INSERT_CAMPAIGN_ID_HERE";
# Specify the keyword text to be created as a negative campaign criterion.
my $keyword = "jupiter cruise";
# Specify the location ID below.
# For more information on determining LOCATION_ID value, see:
# https://developers.google.com/adwords/api/docs/appendix/geotargeting.
my $location_id = 21167;    # NEW YORK

sub add_campaign_targeting_criteria {
  my ($client, $customer_id, $campaign_id, $keyword, $location_id) = @_;

  my $campaign_resource_name =
    Google::Ads::GoogleAds::V1::Utils::ResourceNames::campaign($customer_id,
    $campaign_id);

  my $operations = [
    create_negative_keyword_campaign_criterion_operation(
      $keyword, $campaign_resource_name
    ),
    create_location_campaign_criterion_operation(
      $location_id, $campaign_resource_name
    ),
    create_proximity_campaign_criterion_operation($campaign_resource_name)];

  # Add the campaign criterion.
  my $campaign_criterion_response =
    $client->CampaignCriterionService()->mutate({
      customerId => $customer_id,
      operations => $operations
    });

  my $campaign_criterion_results = $campaign_criterion_response->{results};
  printf "Added %d campaign criteria:\n", scalar @$campaign_criterion_results;

  foreach my $campaign_criterion_result (@$campaign_criterion_results) {
    printf "\t%s\n", $campaign_criterion_result->{resourceName};
  }

  return 1;
}

# Creates a campaign criterion operation using the specified keyword text.
# The keyword text will be used to create a negative campaign criterion.
sub create_negative_keyword_campaign_criterion_operation {
  my ($keyword, $campaign_resource_name) = @_;

  # Construct a negative campaign criterion for the specified campaign
  # using the specified keyword text info.
  my $campaign_criterion =
    Google::Ads::GoogleAds::V1::Resources::CampaignCriterion->new({
      # Create a keyword with BROAD match type.
      keyword => Google::Ads::GoogleAds::V1::Common::KeywordInfo->new({
          text      => $keyword,
          matchType => BROAD
        }
      ),
      # Set the campaign criterion as negative.
      negative => "true",
      campaign => $campaign_resource_name
    });

  return
    Google::Ads::GoogleAds::V1::Services::CampaignCriterionService::CampaignCriterionOperation
    ->new({
      create => $campaign_criterion
    });
}

# Creates a campaign criterion operation using the specified location ID.
sub create_location_campaign_criterion_operation {
  my ($location_id, $campaign_resource_name) = @_;

  # Construct a campaign criterion for the specified campaign using the
  # specified location ID.
  my $campaign_criterion =
    Google::Ads::GoogleAds::V1::Resources::CampaignCriterion->new({
      # Create a location using the specified location ID.
      location => Google::Ads::GoogleAds::V1::Common::LocationInfo->new({
          # Besides using location ID, you can also search by location names
          # using GeoTargetConstantService::suggest() and directly apply
          # GeoTargetConstant->{resourceName} here. An example can be found
          # in get_geo_target_constant_by_names.pl.
          geoTargetConstant =>
            Google::Ads::GoogleAds::V1::Utils::ResourceNames::geo_target_constant(
            $location_id)}
      ),
      campaign => $campaign_resource_name
    });

  return
    Google::Ads::GoogleAds::V1::Services::CampaignCriterionService::CampaignCriterionOperation
    ->new({
      create => $campaign_criterion
    });
}

# Creates a campaign criterion operation for the area around a specific
# address (proximity).
sub create_proximity_campaign_criterion_operation {
  my ($campaign_resource_name) = @_;

  # Construct a campaign criterion as a proximity.
  my $campaign_criterion =
    Google::Ads::GoogleAds::V1::Resources::CampaignCriterion->new({
      proximity => Google::Ads::GoogleAds::V1::Common::ProximityInfo->new({
          address => Google::Ads::GoogleAds::V1::Common::AddressInfo->new({
              streetAddress => "38 avenue de l'Opéra",
              cityName      => "cityName",
              postalCode    => "75002",
              countryCode   => "FR"
            }
          ),
          radius => 10.0,
          # Default is kilometers.
          radiusUnits => MILES
        }
      ),
      campaign => $campaign_resource_name
    });

  return
    Google::Ads::GoogleAds::V1::Services::CampaignCriterionService::CampaignCriterionOperation
    ->new({
      create => $campaign_criterion
    });
}

# Don't run the example if the file is being included.
if (abs_path($0) ne abs_path(__FILE__)) {
  return 1;
}

# Get Google Ads Client, credentials will be read from ~/googleads.properties.
my $client = Google::Ads::GoogleAds::GoogleAdsClient->new({version => "V1"});

# By default examples are set to die on any server returned fault.
$client->set_die_on_faults(1);

# Parameters passed on the command line will override any parameters set in code.
GetOptions(
  "customer_id=s" => \$customer_id,
  "campaign_id=i" => \$campaign_id,
  "keyword=s"     => \$keyword,
  "location_id=i" => \$location_id
);

# Print the help message if the parameters are not initialized in the code nor
# in the command line.
pod2usage(2)
  if not check_params($customer_id, $campaign_id, $keyword, $location_id);

# Call the example.
add_campaign_targeting_criteria($client, $customer_id =~ s/-//gr,
  $campaign_id, $keyword, $location_id);

=pod

=head1 NAME

add_campaign_targeting_criteria

=head1 DESCRIPTION

This example adds campaign targeting criteria. To get campaign targeting criteria,
run get_campaign_targeting_criteria.pl.

=head1 SYNOPSIS

add_campaign_targeting_criteria.pl [options]

    -help                       Show the help message.
    -customer_id                The Google Ads customer ID.
    -campaign_id                The campaign ID.
    -keyword                    [optional] The keyword to be created as a negative
                                campaign criterion.
    -location_id                [optional] The location ID.

=cut
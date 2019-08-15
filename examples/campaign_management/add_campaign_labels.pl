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
# This example adds a campaign label to a list of campaigns.

use strict;
use warnings;
use utf8;

use FindBin qw($Bin);
use lib "$Bin/../../lib";
use Google::Ads::GoogleAds::GoogleAdsClient;
use Google::Ads::GoogleAds::Utils::GoogleAdsHelper;
use Google::Ads::GoogleAds::V1::Resources::CampaignLabel;
use
  Google::Ads::GoogleAds::V1::Services::CampaignLabelService::CampaignLabelOperation;
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
my $customer_id  = "INSERT_CUSTOMER_ID_HERE";
my $campaign_ids = "INSERT_CAMPAIGN_IDS_HERE";
my $label_id     = "INSERT_LABEL_ID_HERE";

sub add_campaign_labels {
  my ($client, $customer_id, $campaign_ids, $label_id) = @_;

  my $label_resource_name =
    Google::Ads::GoogleAds::V1::Utils::ResourceNames::label($customer_id,
    $label_id);

  my $campaign_label_operations = [];

  # Create a campaign label operation for each campaign.
  foreach my $campaign_id (@$campaign_ids) {
    # Create a campaign label.
    my $campaign_label =
      Google::Ads::GoogleAds::V1::Resources::CampaignLabel->new({
        campaign => Google::Ads::GoogleAds::V1::Utils::ResourceNames::campaign(
          $customer_id, $campaign_id
        ),
        label => $label_resource_name
      });

    # Create a campaign label operation.
    my $campaign_label_operation =
      Google::Ads::GoogleAds::V1::Services::CampaignLabelService::CampaignLabelOperation
      ->new({
        create => $campaign_label
      });

    push @$campaign_label_operations, $campaign_label_operation;
  }

  # Add the campaign labels to the campaigns.
  my $campaign_label_response = $client->CampaignLabelService()->mutate({
    customerId => $customer_id,
    operations => $campaign_label_operations
  });

  my $campaign_label_results = $campaign_label_response->{results};
  printf "Added %d campaign labels:\n", scalar @$campaign_label_results;

  foreach my $campaign_label_result (@$campaign_label_results) {
    printf "Created campaign label %s.\n",
      $campaign_label_result->{resourceName};
  }

  return 1;
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
  "customer_id=s"  => \$customer_id,
  "campaign_ids=s" => \$campaign_ids,
  "label_id=i"     => \$label_id
);

# Print the help message if the parameters are not initialized in the code nor
# in the command line.
pod2usage(2) if not check_params($customer_id, $campaign_ids, $label_id);

# Call the example.
add_campaign_labels(
  $client,
  $customer_id =~ s/-//gr,
  [split(/[,\s]+/, $campaign_ids)], $label_id
);

=pod

=head1 NAME

add_campaign_labels

=head1 DESCRIPTION

This example adds a campaign label to a list of campaigns.

=head1 SYNOPSIS

add_campaign_labels.pl [options]

    -help                       Show the help message.
    -customer_id                The Google Ads customer ID.
    -campaign_ids               The comma separated list of campaign IDs.
    -label_id                   The label ID.

=cut
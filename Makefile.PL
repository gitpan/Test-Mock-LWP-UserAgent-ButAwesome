
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "A mock LWP::UserAgent suitable for testing network calls",
  "AUTHOR" => "Karen Etheridge <ether\@cpan.org>",
  "BUILD_REQUIRES" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "HTTP::Request::Common" => 0,
    "Test::CheckDeps" => "0.002",
    "Test::Deep" => 0,
    "Test::More" => "0.88",
    "Test::NoWarnings" => "1.04",
    "URI" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Test-Mock-LWP-UserAgent-ButAwesome",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Test::Mock::LWP::UserAgent::ButAwesome",
  "PREREQ_PM" => {
    "LWP::UserAgent" => 0,
    "Scalar::Util" => 0,
    "Storable" => 0,
    "parent" => 0,
    "re" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "0.001",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);




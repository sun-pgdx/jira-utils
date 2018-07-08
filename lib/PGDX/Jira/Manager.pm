package PGDX::Jira::Manager;

use Moose;
use Cwd;
use File::Path;
use FindBin;

use PGDX::Logger;
use PGDX::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_USERNAME => 'jsundaram';

my $login =  getlogin || getpwuid($<) || "jsundaram";

use constant DEFAULT_OUTDIR => '/tmp/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_JIRA_REST_URL => undef;

use constant DEFAULT_JIRA_ISSUE_REST_URL => undef;

## Singleton support
my $instance;

has 'username' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setUsername',
    reader   => 'getUsername',
    required => FALSE,
    default  => DEFAULT_USERNAME
    );

has 'password' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setPassword',
    reader   => 'getPassword',
    required => FALSE
    );

has 'issue_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIssueURL',
    reader   => 'getIssueURL',
    required => FALSE
    );

has 'jira_rest_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraRESTURL',
    reader   => 'getJiraRESTURL',
    required => FALSE,
    default  => DEFAULT_JIRA_REST_URL
    );

has 'jira_issue_rest_url' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setJiraIssueRESTURL',
    reader   => 'getJiraIssueRESTURL',
    required => FALSE,
    default  => DEFAULT_JIRA_ISSUE_REST_URL
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'project' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setProject',
    reader   => 'getProject',
    required => FALSE
    );

has 'action' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setAction',
    reader   => 'getAction',
    required => FALSE
    );


sub getInstance {

    if (!defined($instance)){

        $instance = new PGDX::Jira::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate PGDX::Jira::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initConfigManager {

    my $self = shift;

    my $manager = PGDX::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate PGDX::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub execute {

    my $self = shift;
    
    my $action = $self->getAction();

    my $project = $self->getProject();

    $self->{_logger}->info("Will execute action '$action' against project '$project'");    
}


sub _getUsername {

    my $self = shift;
    my $username = $self->getUsername();

    if (!defined($username)){

        $username = $self->{_config_manager}->getJiraUsername();

        my $config_file = $self->{_config_manager}->getConfigFile();

        $self->{_logger}->info("username was not defined so was set to '$username' from the configuration file '$config_file'");        

        if (!defined($username)){

            $username = DEFAULT_USERNAME;

            $self->{_logger}->warn("username was not defined so was set to default '$username'");
        }

        $self->setUsername($username);
    }

    return $username;
}

sub _getPassword {

    my $self = shift;

    my $password = $self->getPassword();

    if (!defined($password)){

        $password = $self->{_config_manager}->getJiraPassword();

        my $config_file = $self->{_config_manager}->getConfigFile();

        $self->{_logger}->info("password was not defined so was set to '$password' from the configuration file '$config_file'");        

        if (!defined($password)){

            $password = $self->_prompt_for_jira_password();
        }

        $self->setPassword($password);
    }

    return $password;
}

sub _get_rest_api_issue_end_point {

    my $self = shift;
    my ($issue_id) = @_;

    my $jira_rest_url = $self->_get_jira_rest_url();

    if ($jira_rest_url =~ m|/$|){
        $jira_rest_url =~ s|/+$||;  ## remove all trailing forward slashes
    }

    my $final_url = $jira_rest_url . '/' . $issue_id . '/comment';

    return $final_url;
}

sub _get_jira_rest_url {

    my $self = shift;
    
    my $jira_rest_url = $self->{_config_manager}->getJiraIssueRESTURL();

    if ((!defined($jira_rest_url)) || ($jira_rest_url eq '')){

        my $config_file = $self->{_config_manager}->getConfigFile();

        $self->{_logger}->logconfess("JIRA issue REST URL could not be retrieved from configuration file '$config_file'");
    }

    return $jira_rest_url;
}

sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;
    
    my @results;
 
    $self->{_logger}->info("About to execute '$cmd'");
    
    eval {
        @results = qx($cmd);
    };

    if ($?){
        $self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }


    chomp @results;

    foreach my $line (@results){
        $self->{_logger}->info("$line");
    }

    return \@results;
}

no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 PGDX::Jira::Manager
 
=head1 VERSION

 1.0

=head1 SYNOPSIS

 use PGDX::Jira::Manager;
 my $manager = PGDX::Jira::Manager::getInstance(action => $action, project => $project);
 $manager->execute($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
package PGDX::Jira::SLA::Analyzer;

use Moose;

extends 'PDX::Jira::Project::Analyzer';

use constant TRUE  => 1;

use constant FALSE => 0;


## Singleton support
my $instance;

sub getInstance {

    if (!defined($instance)){

        $instance = new PGDX::Jira::SLA::Analyzer(@_);

        if (!defined($instance)){

            confess "Could not instantiate PGDX::Jira::SLA::Analyzer";
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

sub generateReport {

    my $self = shift;

    $self->_analyze_issues(@_);

    $self->_write_report(@_);
}

sub _write_report {

    my $self = shift;
    
}

    
no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 PGDX::Jira::SLA::Analyzer
 
=head1 VERSION

 1.0

=head1 SYNOPSIS

 use PGDX::Jira::SLA::Analyzer;
 my $manager = PGDX::Jira::SLA::Analyzer::getInstance(action => $action, project => $project);
 $manager->execute($comment);

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
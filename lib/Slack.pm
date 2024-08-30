use strict; use warnings; no warnings qw/experimental/; use feature qw/say signatures/;
package Slack;
use WebService::Slack::WebApi;
use File::Slurp;
sub slack_login() {
   chomp(my $slack_token = read_file('.oauth'));
   my $slack = WebService::Slack::WebApi->new(token => $slack_token) or die "no slack! $!";
   return($slack);
}

use Class::Tiny { auth => sub {slack_login} };
sub msg($self, $txt, $to="random") {
    # to can be a person (e.g. @name) or channel (e.g. random)
    # posting message to specified channel and getting message description
    my $auth = $self->auth;
    my $chat = $auth->chat;
    my $posted_message = $chat->post_message(
         channel  => $to,
         text     => "$txt",
         link_names=>1,
    );

    return($posted_message);
}

1;

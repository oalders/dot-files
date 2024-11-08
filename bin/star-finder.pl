#!/usr/bin/perl
use strict;
use warnings;
use LWP::UserAgent;
use JSON;

my $user_agent = LWP::UserAgent->new;
my $search_url = "https://api.github.com/search/repositories?q=language:Perl+stars:>=200&sort=stars&order=desc";

my $response = $user_agent->get($search_url, 'User-Agent' => 'Perl script');
if ($response->is_success) {
    my $repos = decode_json($response->decoded_content)->{items};

    foreach my $repo (@$repos) {
        my $languages_url = "https://api.github.com/repos/$repo->{full_name}/languages";
        my $lang_response = $user_agent->get($languages_url, 'User-Agent' => 'Perl script');

        if ($lang_response->is_success) {
            my $languages = decode_json($lang_response->decoded_content);
            my $total_lines = 0;
            my $perl_lines = 0;

            foreach my $lang (keys %$languages) {
                $total_lines += $languages->{$lang};
                $perl_lines += $languages->{$lang} if $lang eq 'Perl';
            }

            if ($total_lines > 0 && ($perl_lines / $total_lines) >= 0.5) {
                print "Repo: $repo->{full_name} - Stars: $repo->{stargazers_count}\n";
            }
        } else {
            warn "Failed to fetch languages for $repo->{full_name}: " . $lang_response->status_line;
        }
    }
} else {
    die "Failed to fetch repositories: " . $response->status_line;
}


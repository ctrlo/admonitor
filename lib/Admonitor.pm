=pod
Admonitor - Server monitoring software
Copyright (C) 2015 Ctrl O Ltd

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
=cut

package Admonitor;

use Admonitor::Plugin::Agents;
use Dancer2;
use Dancer2::Plugin::DBIC;
use DateTime::Format::Strptime;
use DateTime::Format::DBI;
use JSON;
use Log::Report;

our $VERSION = '0.1';

any '/' => sub {

    if (param 'submit')
    {
        session 'start' => param('start') if param 'start';
        session 'end'   => param('end') if param 'end';
    }

    my $plugins = Admonitor::Plugin::Agents->new(
        schema => schema,
        config => config,
    )->all;

    my @pnames = map { $_->name } @$plugins;
    template 'index' => {
        plugins => [@pnames],
    };
};

get '/data/?:plugin' => sub {

    my $pname = param 'plugin';
    my $plugin = "Admonitor::Plugin::$pname";
    eval "require $plugin";
    my $p = $plugin->new(
        schema => schema,
        start  => session('start'),
        end    => session('end'),
    );
    my $data = $p->graph_data;

    header "Cache-Control" => "max-age=0, must-revalidate, private";
    content_type 'application/json';
    encode_json($data);
};

true;

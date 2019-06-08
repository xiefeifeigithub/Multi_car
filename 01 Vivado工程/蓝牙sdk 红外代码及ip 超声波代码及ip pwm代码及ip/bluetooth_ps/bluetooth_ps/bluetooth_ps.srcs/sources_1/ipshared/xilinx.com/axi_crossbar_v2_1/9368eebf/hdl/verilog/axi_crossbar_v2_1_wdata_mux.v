heck_path {
	my ($self, $path, $r) = @_;
	my $cache = $self->{cache}->{check_path};
	if ($r == $cache->{r} && exists $cache->{data}->{$path}) {
		return $cache->{data}->{$path};
	}
	my $pool = SVN::Pool->new;
	my $t = $self->SUPER::check_path($path, $r, $pool);
	$pool->clear;
	if ($r != $cache->{r}) {
		%{$cache->{data}} = ();
		$cache->{r} = $r;
	}
	$cache->{data}->{$path} = $t;
}

sub get_dir {
	my ($self, $dir, $r) = @_;
	my $cache = $self->{cache}->{get_dir};
	if ($r == $cache->{r}) {
		if (my $x = $cache->{data}->{$dir}) {
			return wantarray ? @$x : $x->[0];
		}
	}
	my $pool = SVN::Pool->new;
	my ($d, undef, $props) = $self->SUPER::get_dir($dir, $r, $pool);
	my %dirents = map { $_ => { kind => $d->{$_}->kind } } keys %$d;
	$pool->clear;
	if ($r != $cache->{r}) {
		%{$cache->{data}} = ();
		$cache->{r} = $r;
	}
	$cache->{data}->{$dir} = [ \%dirents, $r, $props ];
	wantarray ? (\%dirents, $r, $props) : \%dirents;
}

sub DESTROY {
	# do not call the real DESTROY since we store ourselves in $RA
}

# get_log(paths, start, end, limit,
#         discover_changed_paths, strict_node_history, receiver)
sub get_log {
	my ($self, @args) = @_;
	my $pool = SVN::Pool->new;

	# svn_log_changed_path_t objects passed to get_log are likely to be
	# overwritten even if only the refs are copied to an external variable,
	# so we should dup the structures in their entirety.  Using an
	# externally passed pool (instead of our temporary and quickly cleared
	# pool in Git::SVN::Ra) does not help matters at all...
	my $receiver = pop @args;
	my $prefix = "/".$self->{svn_path};
	$prefix =~ s#/+($)##;
	my $prefix_regex = qr#^\Q$prefix\E#;
	push(@args, sub {
		my ($paths) = $_[0];
		return &$receiver(@_) unless $paths;
		$_[0] = ();
		foreach my $p (keys %$paths) {
			my $i = $paths->{$p};
			# Make path relative to our url, not repos_root
			$p =~ s/$prefix_regex//;
			my %s = map { $_ => $i->$_; }
				qw/copyfrom_path copyfrom_rev action/;
			if ($s{'copyfrom_path'}) {
				$s{'copyfrom_path'} =~ s/$prefix_regex//;
				$s{'copyfrom_path'} = canonicalize_path($s{'copyfrom_path'});
			}
			$_[0]{$p} = \%s;
		}
		&$receiver(@_);
	});


	# the limit parameter was not supported in SVN 1.1.x, so we
	# drop it.  Therefore, the receiver callback passed to it
	# is made aware of this limitation by being wrapped if
	# the limit passed to is being wrapped.
	if (::compare_svn_version('1.2.0') <= 0) {
		my $limit = splice(@args, 3, 1);
		if ($limit > 0) {
			my $receiver = pop @args;
			push(@args, sub { &$receiver(@_) if (--$limit >= 0) });
		}
	}
	my $ret = $self->SUPER::get_log(@args, $pool);
	$pool->clear;
	$ret;
}

sub trees_match {
	my ($self, $url1, $rev1, $url2, $rev2) = @_;
	my $ctx = SVN::Client->new(auth => _auth_providers);
	my $out = IO::File->new_tmpfile;

	# older SVN (1.1.x) doesn't take $pool as the last parameter for
	# $ctx->diff(), so we'll create a default one
	my $pool = SVN::Pool->new_default_sub;

	$ra_invalid = 1; # this will open a new SVN::Ra connection to $url1
	$ctx->diff([], $url1, $rev1, $url2, $rev2, 1, 1, 0, $out, $out);
	$out->flush;
	my $ret = (($out->stat)[7] == 0);
	close $out or croak $!;

	$ret;
}

sub get_commit_editor {
	my ($self, $log, $cb, $pool) = @_;

	my @lock = (::compare_svn_version('1.2.0') >= 0) ? (undef, 0) : ();
	$self->SUPER::get_commit_editor($log, $cb, @lock, $pool);
}

sub gs_do_update {
	my ($self, $rev_a, $rev_b, $gs, $editor) = @_;
	my $new = ($rev_a == $rev_b);
	my $path = $gs->path;

	if ($new && -e $gs->{index}) {
		unlink $gs->{index} or die
		  "Couldn't unlink index: $gs->{index}: $!\n";
	}
	my $pool = SVN::Pool->new;
	$editor->set_path_strip($path);
	my (@pc) = split m#/#, $path;
	my $reporter = $self->do_update($rev_b, (@pc ? shift @pc : ''),
	                                1, $editor, $pool);
	my @lock = (::compare_svn_version('1.2.0') >= 0) ? (undef) : ();

	# Since we can't rely on svn_ra_reparent being available, we'll
	# just have to do some magic with set_path to make it so
	# we only want a partial path.
	my $sp = '';
	my $final = join('/', @pc);
	while (@pc) {
		$reporter->set_path($sp, $rev_b, 0, @lock, $pool);
		$sp .= '/' if length $sp;
		$sp .= shift @pc;
	}
	die "BUG: '$sp' != '$final'\n" if ($sp ne $final);

	$reporter->set_path($sp, $rev_a, $new, @lock, $pool);

	$reporter->finish_report($pool);
	$pool->clear;
	$editor->{git_commit_ok};
}

# this requires SVN 1.4.3 or later (do_switch didn't work before 1.4.3, and
# svn_ra_reparent didn't work before 1.4)
sub gs_do_switch {
	my ($self, $rev_a, $rev_b, $gs, $url_b, $editor) = @_;
	my $path = $gs->path;
	my $pool = SVN::Pool->new;

	my $old_url = $self->url;
	my $full_url = add_path_to_url( $self->url, $path );
	my ($ra, $reparented);

	if ($old_url =~ m#^svn(\+\w+)?://# ||
	    ($full_url =~ m#^https?://# &&
	     canonicalize_url($full_url) ne $full_url)) {
		$_[0] = undef;
		$self = undef;
		$RA = undef;
		$ra = Git::SVN::Ra->new($full_url);
		$ra_invalid = 1;
	} elsif ($old_url ne $full_url) {
		SVN::_Ra::svn_ra_reparent(
			$self->{session},
			canonicalize_url($full_url),
			$pool
		);
		$self->url($full_url);
		$reparented = 1;
	}

	$ra ||= $self;
	$url_b = canonicalize_url($url_b);
	my $reporter = $ra->do_switch($rev_b, '', 1, $url_b, $editor, $pool);
	my @lock = (::compare_svn_version('1.2.0') >= 0) ? (undef) : ();
	$reporter->set_path('', $rev_a, 0, @lock, $pool);
	$reporter->finish_report($pool);

	if ($reparented) {
		SVN::_Ra::svn_ra_reparent($self->{session}, $old_url, $pool);
		$self->url($old_url);
	}

	$pool->clear;
	$editor->{git_commit_ok};
}

sub longest_common_path {
	my ($gsv, $globs) = @_;
	my %common;
	my $common_max = scalar @$gsv;

	foreach my $gs (@$gsv) {
		my @tmp = split m#/#, $gs->path;
		my $p = '';
		foreach (@tmp) {
			$p .= length($p) ? "/$_" : $_;
			$common{$p} ||= 0;
			$common{$p}++;
		}
	}
	$globs ||= [];
	$common_max += scalar @$globs;
	foreach my $glob (@$globs) {
		my @tmp = split m#/#, $glob->{path}->{left};
		my $p = '';
		foreach (@tmp) {
			$p .= length($p) ? "/$_" : $_;
			$common{$p} ||= 0;
			$common{$p}++;
		}
	}

	my $longest_path = '';
	foreach (sort {length $b <=> length $a} keys %common) {
		if ($common{$_} == $common_max) {
			$longest_path = $_;
			last;
		}
	}
	$longest_path;
}

sub gs_fetch_loop_common {
	my ($self, $base, $head, $gsv, $globs) = @_;
	return if ($base > $head);
	my $inc = $_log_window_size;
	my ($min, $max) = ($base, $head < $base + $inc ? $head : $base + $inc);
	my $longest_path = longest_common_path($gsv, $globs);
	my $ra_url = $self->url;
	my $find_trailing_edge;
	while (1) {
		my %revs;
		my $err;
		my $err_handler = $SVN::Error::handler;
		$SVN::Error::handler = sub {
			($err) = @_;
			skip_unknown_revs($err);
		};
		sub _cb {
			my ($paths, $r, $author, $date, $log) = @_;
			[ $paths,
			  { author => $author, date => $date, log => $log } ];
		}
		$self->get_log([$longest_pat
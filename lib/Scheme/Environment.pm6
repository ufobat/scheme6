use v6.c;

unit class Scheme::Environment;

has %.map;
has $.parent;

sub get-build-ins() {
    my %map;
    %map<+>       = sub (*@a) { [+] @a };
    %map<->       = sub (*@a) { [-] @a };
    %map<*>       = sub (*@a) { [*] @a };
    %map</>       = sub (*@a) { [/] @a };
    %map<sqrt>    = sub ($a)  { sqrt($a) };
    %map<display> = sub ($a)  { say $a };
    return %map;
}

method lookup(Str $key) {
    if %!map{ $key }:exists {
        return %!map{ $key };
    } elsif $!parent {
        return $!parent.lookup($key);
    }
    die "'$key' not found" unless %.map{$key}:exists;
}

method set(Pair $p) {
    %.map{$p.key} = $p.value;
}

# construction of environments
method get-global-environment(Scheme::Environment:U: ) {
    self.new: map => get-build-ins;
}

method make-new-scope(Scheme::Environment:D: ) {
    return Scheme::Environment.new: parent => self;
}


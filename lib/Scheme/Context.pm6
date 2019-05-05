class Scheme::Context {
    has Int $.line;
    has Int $.column;
    has $.file;
    has Bool $.is-file = False;
}

role Scheme::Contextual[$context] {

    method context() {
        return $context;
    }

    method dump-tree($level = 0) {
        my $ident  = ' ' x $level;
        my $output = $ident;
        if self ~~ Positional and $context.is-file {
            $output ~= ";;; File {{ $context.file }}\n";
            for self.values -> $v {
                $output ~= $v.dump-tree($level);
            }
        } elsif self ~~ Positional {
            $output ~= "(\t\t{{ $context.line }}:{{ $context.column }}\n";
            for self.values -> $v {
                $output ~= $v.dump-tree($level+1);
            }
            $output ~= $ident ~ ")\n";
        } else {
            $output ~= "{{ self }}\t\t{{ $context.line }}:{{ $context.column }}\n";
        }
        return $output;
    }

}


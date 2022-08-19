# original idea from p6Steve here:
# https://p6steve.wordpress.com/2022/08/16/raku-rust-option-some-none/
# tweaked to be a useful Maybe Monad.

# DONE
# must be able to specify that a function returns a
# Maybe[Int] (or whatever)
# NOTE: you have to use the something helper
#       or manually do: Something.new($x) but Maybe
# sub foo($x) returns Maybe[Int] { something($x); }
#  # works if you poss it an int. blows up if you pass it something else
# sub foo($x) returns Maybe { something($x); }
#  # works
# FIXME
# sub foo() returns Maybe {nothing();}


unit module Definitely;


role HasValue {
    method is-something returns Bool {
        return self.^name eq "Definitely::Some";
    }
}
role Things {                   #a utility Role for both flavalueours of Some
    method gist {
        $.value;                #
    }                           # .gist and .raku are used by .say and .Str
                                # methods ... so we ovalueerride them to make nice
    method raku {               # output
        "(Some[{$.value.^name}] $.value)";
    }

    method Str {
        $.value.Str                    # ~ is the Str concatenate operator, when used
    }                           # as a prefix it coerces its argument to (Str)

    method Num {
        $.value.Num                   # + is the addition operator, when used as a
    }                           # prefix it coerces its argument to (Num)
}

role Maybe[::T] does HasValue is export {}
role Maybe does HasValue is export {}

class None is export does HasValue is Maybe {
    method FALLBACK (*@rest) {
        return self;
    }
}

role Some[::Type] does Things does HasValue is export {    # a parameterized role with a type capture
# role Some[::Type] is export does Things {    # a parameterized role with a type capture
    has Type $.value is required;      # using the type capture for a public attr

    multi method new( $value ) {    # ensure that the value is defined
        die "Can't define a new Some without a value." without $value;
        self.new: :$value
    }
}

role Some does Things does HasValue is export {         # role are multis (Some[Int].new and Some.new)
    has $.s is required;                  # require the attr ... if absent, fail
    has $.value;

    multi method new( ::T $value ) {   # use the type capture in a signature
        die "Died with undefined value" without $value;
        self.new: s => Some[(T)].new(:$value)
    }

    submethod TWEAK {                   # late stage constructor alias $s.value to $.value
        $!value := $!s.value            # for the Some Things role
    }
}

sub something(::T $value) is export {
    return Some[(T)].new(:$value) but Maybe[(T)];
}
sub nothing() is export {
    return None but Maybe;
}

# original idea from p6Steve here:
# https://p6steve.wordpress.com/2022/08/16/raku-rust-option-some-none/
# tweaked to be a useful Maybe Monad.

# DONE
# must be able to specify that a function returns a
# Maybe[Int] (or whatever)
# sub foo($x) returns Maybe[Int] { Some.new(3); }

# TODO
#


unit module Definitely;

role Maybe[::T] is export {}
role Maybe is export {}

role Things {                   #a utility Role for both flavalueours of Some

    method gist {
        "(Some[{$.value.^name}] $.value)"     #
    }                           # .gist and .raku are used by .say and .Str
                                # methods ... so we ovalueerride them to make nice
    method raku {               # output
        "(Some[{$.value.^name}] $.value)"
    }

    method Str {
        ~$.value                    # ~ is the Str concatenate operator, when used
    }                           # as a prefix it coerces its argument to (Str)

    method Numeric {
        +$.value                    # + is the addition operator, when used as a
    }                           # prefix it coerces its argument to (Num)
}

role None is export does Maybe {
# role None is export {
    method FALLBACK (*@rest) {
        None;
    }
}

role Some[::T] does Things does Maybe is export {    # a parameterized role with a type capture
# role Some[::T] is export does Things {    # a parameterized role with a type capture
    has T $.value is required;      # using the type capture for a public attr

    multi method new( $value ) {    # ensure that the valuealue is defined
        die "Can't define a new Some without a value." without $value;
        self.new: :$value
    }
}

role Some does Things does Maybe is export {         # role are multis (Some[Int].new and Some.new)
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

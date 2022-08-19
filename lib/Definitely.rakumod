
=begin pod
=head1 NAME
Definitely - An implementation of the Maybe Monad

=head1 SYNOPSIS

=begin code :lang<raku>
use Definitely;

multi sub foo($x) returns Maybe[Int] {
  $x ~~ Int ?? something($x) !! nothing(Int);
}
multi sub foo($x) returns Maybe {
  2.rand.Int == 1 ?? something($x) !! nothing();
}

# explicitly handle questionable results
given foo(3) {
  when $_ ~~ Some {say "'Tis a thing Papa!. Look: $_"}
  default {say "'Tis nothing.'"}
}
# or
my Maybe[Int] $questionable_result = foo(3)
if $questionable_result.is-something {
    # extract the value directly
    return $questionable_result.value + 4;
}

=end code


=head1 EXPORTED SUBROUTINES
There are 3 simple helper methods to make your life a bit easier.

=head2 something(Any)
Takes a single argument and returns a Some[Type] but Maybe[Type]

=head2 nothing(Any)
Takes a type argument and returns None but Maybe[Type].

Use this when your method returns a typed or untyped Maybe.

=head2 nothing()
Takels no arguments and returns None but Maybe.

Use this only when your method returns an untyped Maybe.

=head1 DESCRIPTION
=para
The L<Maybe Monad|https://en.wikipedia.org/wiki/Monad_(functional_programming)#An_example:_Maybe>
is a technique for avoiding unexpected Nil exceptions or having to
explicitly test for Nil in a method's response.

=para
C<Some> & C<None> both provide an C<.is-something> method, if you want
to explicitly test if you have something. You can explicitly extract the
value from a Maybe object by calling C<.value> on it.

C<None> provides a C<FALLBACK>
method that returns the same None object. This means that you can call method
chains on it as if it were the thing you hoped for without blowing up.
Obviously, you'd only do this if your system would be ok with
nothing happening as a result of these calls. For example, logging is nice,
but you probably want your system to carry on even if the logging
mechanism is unavailable.

=begin code :lang<raku>

multi sub logger($x) returns Maybe[Logger] {
  nothing(Logger)
}

logger().record_error("does nothing, and doesn't blow up")
=end code



=para
Many racoons argue that because Raku has typed Nils, the Maybe Monad
is already built in. See L<this Stack Overflow answer|https://stackoverflow.com/questions/55072228/creating-a-maybe-type-in-perl-6>
for more details. Even if they're right, people like me would argue
that there's a huge maintainability value to having code that makes
it I<explicit> that I<Maybe> the value you get back from a method
won't be what you were hoping for.




=head2 AUTHORS
The seed of this comes from L<This post by p6Steve|https://p6steve.wordpress.com/2022/08/16/raku-rust-option-some-none/>.
I (L<masukomi|https://masukomi.org>) have built it out into a full
Maybe Monad implementation as a Raku module.

=head2 LICENSE
The Artistic License 2.0 Copyright (c) 2022, The Perl Foundation.
=end pod


# DONE
# must be able to specify that a function returns a
# Maybe[Int] (or whatever)
# NOTE: you have to use the something helper
#       or manually do: Something.new($x) but Maybe
# sub foo($x) returns Maybe[Int] { something($x); }
#  # works if you poss it an int. blows up if you pass it something else
# sub foo($x) returns Maybe { something($x); }
#  # works
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

role None does HasValue is export {
    method FALLBACK (*@rest) {
        return None;
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

sub something(::Type $value) is export {
    return Some[(Type)].new(:$value) but Maybe[(Type)];
}
multi sub nothing(::Type) is export {
    return None.new() but Maybe[(Type)];
}
multi sub nothing() is export {
    return None.new() but Maybe;
}

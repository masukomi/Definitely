
=begin pod
=head1 NAME
Definitely (Maybe) - An implementation of the Maybe Monad

=head2 DESCRIPTION
=para
The L<Maybe Monad|https://en.wikipedia.org/wiki/Monad_(functional_programming)#An_example:_Maybe>
is a technique for avoiding unexpected Nil exceptions or having to
explicitly test for Nil in a method's response.

=para
C<Some> & C<None> both provide an C<.is-something> method, if you want
to explicitly test if you have something. You can explicitly extract the
value from a Maybe object by calling C<.value> on it.

=para
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
Many racoons argue that because Raku has typed C<Nil>s, the Maybe Monad
is already built in. See L<this Stack Overflow answer|https://stackoverflow.com/questions/55072228/creating-a-maybe-type-in-perl-6>
for more details. Even if they're right, people like me would argue
that there's a huge maintainability value to having code that makes
it I<explicit> that I<Maybe> the value you get back from a method
won't be what you were hoping for.


=head2 USAGE
=para
The core idea is simple. When creating a function specify it's return type as
C<Maybe> or C<Maybe[Type]>. Within the function you'll use the C<something(Any)>
and C<nothing()> or C<nothing(Type)> helper functions to provide a C<Maybe> /
C<Maybe[Type]> compatible object to your caller. The caller then has multiple
choices for how to handle the result.



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
# or, call the .is-something method
my Maybe[Int] $questionable_result = foo(3)
if $questionable_result.is-something {
    # extract the value directly
    return $questionable_result.value + 4;
}
# or, test truthyness (Some is True None is False)
my Maybe[Int] $questionable_result = foo(4);
?$questionable_result ?? $questionable_result.value !! die "oh no!"

# or, just assume it's good if you don't care if calls have no result
my Maybe[Logger] $maybe_log = logger();
$maybe_log.report_error("called if logger is Some, ignored if None")

=end code


=head2 EXPORTED SUBROUTINES
=para
There are four simple helper methods to make your life a bit easier.

=head3 something(Any)
=para
Takes a single argument and returns a Some[Type] but Maybe[Type]

=head3 nothing(Any)
=para
Takes a type argument and returns None but Maybe[Type].

Use this when your method returns a typed or untyped Maybe.

=head3 nothing()
=para
Takes no arguments and returns None but Maybe.

Use this only when your method returns an untyped Maybe.

=head3 value-or-die(Maybe $maybe_obj, Str $message)
=para
Extracts the value from the provided Maybe object or dies with your message.





=head2 AUTHORS
=para
The seed of this comes from L<This post by p6Steve|https://p6steve.wordpress.com/2022/08/16/raku-rust-option-some-none/>.
L<masukomi|https://masukomi.org>) built it out into a full
Maybe Monad implementation as a Raku module.

=head2 LICENSE
The Artistic License 2.0 Copyright (c) 2022, The Perl Foundation.
=end pod

unit module Definitely:ver<1.0.0>:auth<masukomi (masukomi@masukomi.org)>; # (Maybe)


#| provides the is-something method to Some, None, & Many
role HasValue {
    #| Returns true for Some
    method is-something returns Bool {
        return $.Bool
    }
}
role Things {                   #a utility Role for both flavours of Some
    method gist {
        $.value;                #
    }                           # .gist and .raku are used by .say and .Str
                                # methods ... so we ovalueerride them to make nice
    method raku {               # output
        "(Some[{$.value.^name}] $.value)";
    }

    method Str {
        $.value.Str
    }

    method Num {
        $.value.Num
    }

    method Bool {True}
}

#| Typed Maybe - use for defining the object type your method returns
role Maybe[::T] does HasValue is export {}
#| Untype Maybe - use when you don't know or care what type your method returns
role Maybe does HasValue is export {}

#| If your method returns Maybe, but you don't have a valid value, return None
role None does HasValue is export {
    method Bool { False }
    method FALLBACK (*@rest) {
        return None;
    }
}

#| Typed Some - Untyped some uses this too
role Some[::Type] does Things does HasValue is export {
    has Type $.value is required;      # using the type capture for a public attr

    multi method new( $value ) {    # ensure that the value is defined
        die "Can't define a new Some without a value." without $value;
        self.new: :$value
    }
}

#| Untyped Some - Passes through to typed Some.
role Some does Things does HasValue is export {
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

#| simple creation of Some objects that also match the Maybe type
sub something(::Type $value) is export {
    return Some[(Type)].new(:$value) but Maybe[(Type)];
}

#| use to create None objects when your method returns a typed Maybe
multi sub nothing(::Type) is export {
    return None.new() but Maybe[(Type)];
}

#| simple creation of untyped None objects that also match the Maybe type
multi sub nothing() is export {
    return None.new() but Maybe;
}

#| extracts the value from a Maybe object or dies with your message
sub value-or-die (Maybe $maybe_obj, Str $message) is export {
    $maybe_obj ~~ Some ?? $maybe_obj.value !! die $message;
}

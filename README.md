NAME Definitely (Maybe) - An implementation of the Maybe Monad
==============================================================

DESCRIPTION
-----------

The [Maybe Monad](https://en.wikipedia.org/wiki/Monad_(functional_programming)#An_example:_Maybe) is a technique for avoiding unexpected Nil exceptions or having to explicitly test for Nil in a method's response.

`Some` & `None` both provide an `.is-something` method, if you want to explicitly test if you have something. You can explicitly extract the value from a Maybe object by calling `.value` on it.

`None` provides a `FALLBACK` method that returns the same None object. This means that you can call method chains on it as if it were the thing you hoped for without blowing up. Obviously, you'd only do this if your system would be ok with nothing happening as a result of these calls. For example, logging is nice, but you probably want your system to carry on even if the logging mechanism is unavailable.

```raku
multi sub logger($x) returns Maybe[Logger] {
  nothing(Logger)
}

logger().record_error("does nothing, and doesn't blow up")
```

Many racoons argue that because Raku has typed `Nil`s, the Maybe Monad is already built in. See [this Stack Overflow answer](https://stackoverflow.com/questions/55072228/creating-a-maybe-type-in-perl-6) for more details. Even if they're right, people like me would argue that there's a huge maintainability value to having code that makes it *explicit* that *Maybe* the value you get back from a method won't be what you were hoping for.

USAGE
-----

The core idea is simple. When creating a function specify it's return type as `Maybe` or `Maybe[Type]`. Within the function you'll use the `something(Any)` and `nothing()` or `nothing(Type)` helper functions to provide a `Maybe` / `Maybe[Type]` compatible object to your caller. The caller then has multiple choices for how to handle the result.

```raku
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
```

EXPORTED SUBROUTINES
--------------------

There are four simple helper methods to make your life a bit easier.

### something(Any)

Takes a single argument and returns a Some[Type] but Maybe[Type]

### nothing(Any)

Takes a type argument and returns None but Maybe[Type].

Use this when your method returns a typed or untyped Maybe.

### nothing()

Takes no arguments and returns None but Maybe.

Use this only when your method returns an untyped Maybe.

### value-or-die(Maybe $maybe_obj, Str $message)

Extracts the value from the provided Maybe object or dies with your message.

AUTHORS
-------

The seed of this comes from [This post by p6Steve](https://p6steve.wordpress.com/2022/08/16/raku-rust-option-some-none/). [masukomi](https://masukomi.org)) built it out into a full Maybe Monad implementation as a Raku module.

LICENSE The Artistic License 2.0 Copyright (c) 2022, The Perl Foundation.
-------------------------------------------------------------------------



provides the is-something method to Some, None, & Many

### method is-something

```raku
method is-something() returns Bool
```

Returns true for Some



Typed Maybe - use for defining the object type your method returns



Untype Maybe - use when you don't know or care what type your method returns



If your method returns Maybe, but you don't have a valid value, return None



Typed Some - Untyped some uses this too



Untyped Some - Passes through to typed Some.

### sub something

```raku
sub something(
    ::Type  $value
) returns Mu
```

simple creation of Some objects that also match the Maybe type

### multi sub nothing

```raku
multi sub nothing(
    ::Type  $
) returns Mu
```

use to create None objects when your method returns a typed Maybe

### multi sub nothing

```raku
multi sub nothing() returns Mu
```

simple creation of untyped None objects that also match the Maybe type

### sub value-or-die

```raku
sub value-or-die(
    Definitely::Maybe $maybe_obj,
    Str $message
) returns Mu
```

extracts the value from a Maybe object or dies with your message


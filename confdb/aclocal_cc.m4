dnl
dnl This is a replacement for AC_PROG_CC that does not prefer gcc and
dnl that does not mess with CFLAGS.  See acspecific.m4 for the original defn.
dnl
dnl/*D
dnl PAC_PROG_CC - Find a working C compiler
dnl
dnl Synopsis:
dnl PAC_PROG_CC
dnl
dnl Output Effect:
dnl   Sets the variable CC if it is not already set
dnl
dnl Notes:
dnl   Unlike AC_PROG_CC, this does not prefer gcc and does not set CFLAGS.
dnl   It does check that the compiler can compile a simple C program.
dnl   It also sets the variable GCC to yes if the compiler is gcc.  It does
dnl   not yet check for some special options needed in particular for 
dnl   parallel computers, such as -Tcray-t3e, or special options to get
dnl   full ANSI/ISO C, such as -Aa for HP.
dnl
dnl D*/
dnl 2.52 doesn't have AC_PROG_CC_GNU
ifdef([AC_PROG_CC_GNU],,[AC_DEFUN([AC_PROG_CC_GNU],)])
AC_DEFUN([PAC_PROG_CC],[
AC_PROVIDE([AC_PROG_CC])
AC_CHECK_PROGS(CC, cc xlC xlc pgcc icc pathcc gcc )
test -z "$CC" && AC_MSG_ERROR([no acceptable cc found in \$PATH])
PAC_PROG_CC_WORKS
AC_PROG_CC_GNU
if test "$ac_cv_prog_gcc" = yes; then
  GCC=yes
else
  GCC=
fi
])
dnl
dnl/*D
dnl PAC_C_CHECK_COMPILER_OPTION - Check that a compiler option is accepted
dnl without warning messages
dnl
dnl Synopsis:
dnl PAC_C_CHECK_COMPILER_OPTION(optionname,action-if-ok,action-if-fail)
dnl
dnl Output Effects:
dnl
dnl If no actions are specified, a working value is added to 'COPTIONS'
dnl
dnl Notes:
dnl This is now careful to check that the output is different, since 
dnl some compilers are noisy.
dnl 
dnl We are extra careful to prototype the functions in case compiler options
dnl that complain about poor code are in effect.
dnl
dnl Because this is a long script, we have ensured that you can pass a 
dnl variable containing the option name as the first argument.
dnl
dnl gcc 4.2.4 on 32-bit does not complain about the -Wno-type-limits option 
dnl even though it doesn't support it.  However, when another warning is 
dnl triggered, it gives an error that the option is not recognized.  So we 
dnl need to test with a conftest file that will generate warnings
dnl D*/
AC_DEFUN([PAC_C_CHECK_COMPILER_OPTION],[
AC_MSG_CHECKING([whether C compiler accepts option $1])
pccco_save_CFLAGS="$CFLAGS"
CFLAGS="$1 $CFLAGS"
rm -f conftest.out
pac_success=no
# conftest3.c has an invalid prototype to ensure we generate warnings
echo 'int main(){}' > conftest3.c
echo 'int foo(void);int foo(void){return 0;}' > conftest2.c
echo 'int main(void);int main(void){return 0;}' > conftest.c
if ${CC-cc} $CFLAGS $CPPFLAGS -o conftest conftest3.c $LDFLAGS >/dev/null 2>&1 &&
   ${CC-cc} $pccco_save_CFLAGS $CPPFLAGS -o conftest conftest.c $LDFLAGS >conftest.bas 2>&1 ; then
   if ${CC-cc} $CFLAGS $CPPFLAGS -o conftest conftest.c $LDFLAGS >conftest.out 2>&1 ; then
      if diff -b conftest.out conftest.bas >/dev/null 2>&1 ; then
         AC_MSG_RESULT(yes)
         AC_MSG_CHECKING([whether routines compiled with $1 can be linked with ones compiled without $1])       
         rm -f conftest.out
         rm -f conftest.bas
         if ${CC-cc} -c $pccco_save_CFLAGS $CPPFLAGS conftest2.c >conftest2.out 2>&1 ; then
            if ${CC-cc} $CFLAGS $CPPFLAGS -o conftest conftest2.o conftest.c $LDFLAGS >conftest.bas 2>&1 ; then
               if ${CC-cc} $CFLAGS $CPPFLAGS -o conftest conftest2.o conftest.c $LDFLAGS >conftest.out 2>&1 ; then
                  if diff -b conftest.out conftest.bas >/dev/null 2>&1 ; then
		     pac_success=yes
                  else
		     :
                  fi  
               else
                  :
               fi
	    else
               # Could not link with the option!
	       :
            fi
         else
            if test -s conftest2.out ; then
               cat conftest2.out >&AC_FD_CC
            fi
         fi
      else
         :
      fi
   else
       :
   fi
else
    # Could not compile without the option!
    :
fi
CFLAGS="$pccco_save_CFLAGS"
if test "$pac_success" = yes ; then
   AC_MSG_RESULT(yes)	  
   ifelse($2,,COPTIONS="$COPTIONS $1",$2)
else
   AC_MSG_RESULT(no)
   if test -s conftest.out ; then cat conftest.out >&AC_FD_CC ; fi    
   $3
fi
# This is needed for Mac OSX 10.5
rm -rf conftest.dSYM
rm -f conftest*
])
dnl
dnl/*D
dnl PAC_C_OPTIMIZATION - Determine C options for producing optimized code
dnl
dnl Synopsis
dnl PAC_C_OPTIMIZATION([action if found])
dnl
dnl Output Effect:
dnl Adds options to 'COPTIONS' if no other action is specified
dnl 
dnl Notes:
dnl This is a temporary standin for compiler optimization.
dnl It should try to match known systems to known compilers (checking, of
dnl course), and then falling back to some common defaults.
dnl Note that many compilers will complain about -g and aggressive
dnl optimization.  
dnl D*/
AC_DEFUN([PAC_C_OPTIMIZATION],[
    for copt in "-O4 -Ofast" "-Ofast" "-fast" "-O3" "-xO3" "-O" ; do
        PAC_C_CHECK_COMPILER_OPTION($copt,found_opt=yes,found_opt=no)
        if test "$found_opt" = "yes" ; then
	    ifelse($1,,COPTIONS="$COPTIONS $copt",$1)
	    break
        fi
    done
    if test "$ac_cv_prog_gcc" = "yes" ; then
	for copt in "-fomit-frame-pointer" "-finline-functions" \
		 "-funroll-loops" ; do
	    PAC_C_CHECK_COMPILER_OPTION($copt,found_opt=yes,found_opt=no)
	    if test "$found_opt" = "yes" ; then
	        ifelse($1,,COPTIONS="$COPTIONS $copt",$1)
	        # no break because we're trying to add them all
	    fi
	done
	# We could also look for architecture-specific gcc options
    fi

])

dnl/*D
dnl PAC_PROG_C_UNALIGNED_DOUBLES - Check that the C compiler allows unaligned
dnl doubles
dnl
dnl Synopsis:
dnl   PAC_PROG_C_UNALIGNED_DOUBLES(action-if-true,action-if-false,
dnl       action-if-unknown)
dnl
dnl Notes:
dnl 'action-if-unknown' is used in the case of cross-compilation.
dnl D*/
AC_DEFUN([PAC_PROG_C_UNALIGNED_DOUBLES],[
AC_CACHE_CHECK([whether C compiler allows unaligned doubles],
pac_cv_prog_c_unaligned_doubles,[
AC_TRY_RUN([
void fetch_double( v )
double *v;
{
*v = 1.0;
}
int main( argc, argv )
int argc;
char **argv;
{
int p[4];
double *p_val;
fetch_double( (double *)&(p[0]) );
p_val = (double *)&(p[0]);
if (*p_val != 1.0) return 1;
fetch_double( (double *)&(p[1]) );
p_val = (double *)&(p[1]);
if (*p_val != 1.0) return 1;
return 0;
}
],pac_cv_prog_c_unaligned_doubles="yes",pac_cv_prog_c_unaligned_doubles="no",
pac_cv_prog_c_unaligned_doubles="unknown")])
ifelse($1,,,if test "X$pac_cv_prog_c_unaligned_doubles" = "yes" ; then 
$1
fi)
ifelse($2,,,if test "X$pac_cv_prog_c_unaligned_doubles" = "no" ; then 
$2
fi)
ifelse($3,,,if test "X$pac_cv_prog_c_unaligned_doubles" = "unknown" ; then 
$3
fi)
])

dnl/*D 
dnl PAC_PROG_C_WEAK_SYMBOLS - Test whether C supports weak alias symbols.
dnl
dnl Synopsis
dnl PAC_PROG_C_WEAK_SYMBOLS(action-if-true,action-if-false)
dnl
dnl Output Effect:
dnl Defines one of the following if a weak symbol pragma is found:
dnl.vb
dnl    HAVE_PRAGMA_WEAK - #pragma weak
dnl    HAVE_PRAGMA_HP_SEC_DEF - #pragma _HP_SECONDARY_DEF
dnl    HAVE_PRAGMA_CRI_DUP  - #pragma _CRI duplicate x as y
dnl.ve
dnl May also define
dnl.vb
dnl    HAVE_WEAK_ATTRIBUTE
dnl.ve
dnl if functions can be declared as 'int foo(...) __attribute__ ((weak));'
dnl sets the shell variable pac_cv_attr_weak to yes.
dnl Also checks for __attribute__((weak_import)) which is supported by
dnl Apple in Mac OSX (at least in Darwin).  Note that this provides only
dnl weak symbols, not weak aliases
dnl 
dnl D*/
AC_DEFUN([PAC_PROG_C_WEAK_SYMBOLS],[
pragma_extra_message=""
AC_CACHE_CHECK([for type of weak symbol alias support],
pac_cv_prog_c_weak_symbols,[
# Test for weak symbol support...
# We can't put # in the message because it causes autoconf to generate
# incorrect code
AC_TRY_LINK([
extern int PFoo(int);
#pragma weak PFoo = Foo
int Foo(int a) { return a; }
],[return PFoo(1);],has_pragma_weak=yes)
#
# Some systems (Linux ia64 and ecc, for example), support weak symbols
# only within a single object file!  This tests that case.
# Note that there is an extern int PFoo declaration before the
# pragma.  Some compilers require this in order to make the weak symbol
# extenally visible.  
if test "$has_pragma_weak" = yes ; then
    # This is needed for Mac OSX 10.5
    rm -rf conftest.dSYM
    rm -f conftest*
    cat >>conftest1.c <<EOF
extern int PFoo(int);
#pragma weak PFoo = Foo
int Foo(int);
int Foo(int a) { return a; }
EOF
    cat >>conftest2.c <<EOF
extern int PFoo(int);
int main(int argc, char **argv) {
return PFoo(0);}
EOF
    ac_link2='${CC-cc} -o conftest $CFLAGS $CPPFLAGS $LDFLAGS conftest1.c conftest2.c $LIBS >conftest.out 2>&1'
    if eval $ac_link2 ; then
        # The gcc 3.4.x compiler accepts the pragma weak, but does not
        # correctly implement it on systems where the loader doesn't 
        # support weak symbols (e.g., cygwin).  This is a bug in gcc, but it
        # it is one that *we* have to detect.
	# This is needed for Mac OSX 10.5
	rm -rf conftest.dSYM
        rm -f conftest*
        cat >>conftest1.c <<EOF
extern int PFoo(int);
#pragma weak PFoo = Foo
int Foo(int);
int Foo(int a) { return a; }
EOF
    cat >>conftest2.c <<EOF
extern int Foo(int);
int PFoo(int a) { return a+1;}
int main(int argc, char **argv) {
return Foo(0);}
EOF
        if eval $ac_link2 ; then
            pac_cv_prog_c_weak_symbols="pragma weak"
        else 
            echo "$ac_link2" >> config.log
	    echo "Failed program was" >> config.log
            cat conftest1.c >>config.log
            cat conftest2.c >>config.log
            if test -s conftest.out ; then cat conftest.out >> config.log ; fi
            has_pragma_weak=0
            pragma_extra_message="pragma weak accepted but does not work (probably creates two non-weak entries)"
        fi
    else
      echo "$ac_link2" >>config.log
      echo "Failed program was" >>config.log
      cat conftest1.c >>config.log
      cat conftest2.c >>config.log
      if test -s conftest.out ; then cat conftest.out >> config.log ; fi
      has_pragma_weak=0
      pragma_extra_message="pragma weak does not work outside of a file"
    fi
    # This is needed for Mac OSX 10.5
    rm -rf conftest.dSYM
    rm -f conftest*
fi
dnl
if test -z "$pac_cv_prog_c_weak_symbols" ; then 
    AC_TRY_LINK([
extern int PFoo(int);
#pragma _HP_SECONDARY_DEF Foo  PFoo
int Foo(int a) { return a; }
],[return PFoo(1);],pac_cv_prog_c_weak_symbols="pragma _HP_SECONDARY_DEF")
fi
dnl
if test -z "$pac_cv_prog_c_weak_symbols" ; then
    AC_TRY_LINK([
extern int PFoo(int);
#pragma _CRI duplicate PFoo as Foo
int Foo(int a) { return a; }
],[return PFoo(1);],pac_cv_prog_c_weak_symbols="pragma _CRI duplicate x as y")
fi
dnl
if test -z "$pac_cv_prog_c_weak_symbols" ; then
    pac_cv_prog_c_weak_symbols="no"
fi
dnl
dnl If there is an extra explanatory message, echo it now so that it
dnl doesn't interfere with the cache result value
if test -n "$pragma_extra_message" ; then
    echo $pragma_extra_message
fi
dnl
])
if test "$pac_cv_prog_c_weak_symbols" = "no" ; then
    ifelse([$2],,:,[$2])
else
    case "$pac_cv_prog_c_weak_symbols" in
	"pragma weak") AC_DEFINE(HAVE_PRAGMA_WEAK,1,[Supports weak pragma]) 
	;;
	"pragma _HP")  AC_DEFINE(HAVE_PRAGMA_HP_SEC_DEF,1,[HP style weak pragma])
	;;
	"pragma _CRI") AC_DEFINE(HAVE_PRAGMA_CRI_DUP,1,[Cray style weak pragma])
	;;
    esac
    ifelse([$1],,:,[$1])
fi
AC_CACHE_CHECK([whether __attribute__ ((weak)) allowed],
pac_cv_attr_weak,[
AC_TRY_COMPILE([int foo(int) __attribute__ ((weak));],[int a;],
pac_cv_attr_weak=yes,pac_cv_attr_weak=no)])
# Note that being able to compile with weak_import doesn't mean that 
# it works.
AC_CACHE_CHECK([whether __attribute ((weak_import)) allowed],
pac_cv_attr_weak_import,[
AC_TRY_COMPILE([int foo(int) __attribute__ ((weak_import));],[int a;],
pac_cv_attr_weak_import=yes,pac_cv_attr_weak_import=no)])
])

#
# This is a replacement that checks that FAILURES are signaled as well
# (later configure macros look for the .o file, not just success from the
# compiler, but they should not HAVE to
#
dnl --- insert 2.52 compatibility here ---
dnl 2.52 does not have AC_PROG_CC_WORKS
ifdef([AC_PROG_CC_WORKS],,[AC_DEFUN([AC_PROG_CC_WORKS],)])
dnl
AC_DEFUN([PAC_PROG_CC_WORKS],
[AC_PROG_CC_WORKS
AC_MSG_CHECKING([whether the C compiler sets its return status correctly])
AC_LANG_SAVE
AC_LANG_C
AC_TRY_COMPILE(,[int a = bzzzt;],notbroken=no,notbroken=yes)
AC_MSG_RESULT($notbroken)
if test "$notbroken" = "no" ; then
    AC_MSG_ERROR([installation or configuration problem: C compiler does not
correctly set error code when a fatal error occurs])
fi
])

dnl/*D 
dnl PAC_PROG_C_MULTIPLE_WEAK_SYMBOLS - Test whether C and the
dnl linker allow multiple weak symbols.
dnl
dnl Synopsis
dnl PAC_PROG_C_MULTIPLE_WEAK_SYMBOLS(action-if-true,action-if-false)
dnl
dnl 
dnl D*/
AC_DEFUN([PAC_PROG_C_MULTIPLE_WEAK_SYMBOLS],[
AC_CACHE_CHECK([for multiple weak symbol support],
pac_cv_prog_c_multiple_weak_symbols,[
# Test for multiple weak symbol support...
#
# This is needed for Mac OSX 10.5
rm -rf conftest.dSYM
rm -f conftest*
cat >>conftest1.c <<EOF
extern int PFoo(int);
extern int PFoo_(int);
extern int pfoo_(int);
#pragma weak PFoo = Foo
#pragma weak PFoo_ = Foo
#pragma weak pfoo_ = Foo
int Foo(int);
int Foo(a) { return a; }
EOF
cat >>conftest2.c <<EOF
extern int PFoo(int), PFoo_(int), pfoo_(int);
int main() {
return PFoo(0) + PFoo_(1) + pfoo_(2);}
EOF
ac_link2='${CC-cc} -o conftest $CFLAGS $CPPFLAGS $LDFLAGS conftest1.c conftest2.c $LIBS >conftest.out 2>&1'
if eval $ac_link2 ; then
    pac_cv_prog_c_multiple_weak_symbols="yes"
else
    echo "$ac_link2" >>config.log
    echo "Failed program was" >>config.log
    cat conftest1.c >>config.log
    cat conftest2.c >>config.log
    if test -s conftest.out ; then cat conftest.out >> config.log ; fi
fi
# This is needed for Mac OSX 10.5
rm -rf conftest.dSYM
rm -f conftest*
dnl
])
if test "$pac_cv_prog_c_multiple_weak_symbols" = "yes" ; then
    ifelse([$1],,:,[$1])
else
    ifelse([$2],,:,[$2])
fi
])

dnl Use the value of enable-strict to update CFLAGS
dnl pac_cc_strict_flags contains the strict flags.
dnl
dnl -std=c89 is used to select the C89 version of the ANSI/ISO C standard.
dnl As of this writing, many C compilers still accepted only this version,
dnl not the later C99 version. When all compilers accept C99, this 
dnl should be changed to the appropriate standard level.  Note that we've
dnl had trouble with gcc 2.95.3 accepting -std=c89 but then trying to 
dnl compile program with a invalid set of options 
dnl (-D __STRICT_ANSI__-trigraphs)
AC_DEFUN([PAC_CC_STRICT],[
export enable_strict_done
if test "$enable_strict_done" != "yes" ; then

    # Some comments on strict warning options.
    # These were added to reduce warnings:
    #   -Wno-missing-field-initializers  -- We want to allow a struct to be 
    #       initialized to zero using "struct x y = {0};" and not require 
    #       each field to be initialized individually.
    #   -Wno-unused-parameter -- For portability, some parameters go unused
    #	    when we have different implementations of functions for 
    #	    different platforms
    #   -Wno-unused-label -- We add fn_exit: and fn_fail: on all functions, 
    #	    but fn_fail may not be used if the function doesn't return an 
    #	    error.
    #   -Wno-sign-compare -- read() and write() return bytes read/written
    #       as a signed value, but we often compare this to size_t (or
    #	    msg_sz_t) variables.
    #   -Wno-format-zero-length -- this warning is irritating and useless, since
    #                              a zero-length format string is very well defined
    #   -Wno-type-limits -- There are places where we compare an unsigned to 
    #	    a constant that happens to be zero e.g., if x is unsigned and 
    #	    MIN_VAL is zero, we'd like to do "MPIU_Assert(x >= MIN_VAL);".
    #       Note this option is not supported by gcc 4.2.  This needs to be added 
    #	    after most other warning flags, so that we catch a gcc bug on 32-bit 
    #	    that doesn't give a warning that this is unsupported, unless another
    #	    warning is triggered, and then if gives an error.
    # These were removed to reduce warnings:
    #   -Wcast-qual -- Sometimes we need to cast "volatile char*" to 
    #	    "char*", e.g., for memcpy.
    #   -Wpadded -- We catch struct padding with asserts when we need to
    #   -Wredundant-decls -- Having redundant declarations is benign and the 
    #	    code already has some.
    #   -Waggregate-return -- This seems to be a performance-related warning
    #       aggregate return values are legal in ANSI C, but they may be returned
    #	    in memory rather than through a register.  We do use aggregate return
    #	    values, but they are structs of a single basic type (used to enforce
    #	    type checking for relative vs. absolute ptrs), and with optimization
    #	    the aggregate value is converted to a scalar.
    # the embedded newlines in this string are safe because we evaluate each
    # argument in the for-loop below and append them to the CFLAGS with a space
    # as the separator instead
    pac_common_strict_flags="
        -Wall
        -Wextra
        -Wno-missing-field-initializers
        -Wstrict-prototypes
        -Wmissing-prototypes
        -DGCC_WALL
        -Wno-unused-parameter
        -Wno-unused-label
        -Wshadow
        -Wmissing-declarations
        -Wno-long-long
        -Wfloat-equal
        -Wdeclaration-after-statement
        -Wundef
        -Wno-endif-labels
        -Wpointer-arith
        -Wbad-function-cast
        -Wcast-align
        -Wwrite-strings
        -Wno-sign-compare
        -Wold-style-definition
        -Wno-multichar
        -Wno-deprecated-declarations
        -Wpacked
        -Wnested-externs
        -Winvalid-pch
        -Wno-pointer-sign
        -Wvariadic-macros
        -std=c89
        -Wno-format-zero-length
	-Wno-type-limits
    "
    pac_cc_strict_flags=""
    case "$1" in 
        yes|all|posix)
		enable_strict_done="yes"
		pac_cc_strict_flags="-O2 $pac_common_strict_flags -D_POSIX_C_SOURCE=199506L"
        ;;

        noposix)
		enable_strict_done="yes"
		pac_cc_strict_flags="-O2 $pac_common_strict_flags"
        ;;

	noopt)
		enable_strict_done="yes"
		pac_cc_strict_flags="$pac_common_strict_flags -D_POSIX_C_SOURCE=199506L"
	;;
        
        no)
		# Accept and ignore this value
		:
        ;;

        *)
		if test -n "$1" ; then
		   AC_MSG_WARN([Unrecognized value for enable-strict:$1])
		fi
        ;;

    esac

    # See if the above options work with the compiler
    accepted_flags=""
    for flag in $pac_cc_strict_flags ; do
        # the save_CFLAGS variable must be namespaced, otherwise they
        # may not actually be saved if an invoked macro also uses
        # save_CFLAGS
        pcs_save_CFLAGS=$CFLAGS
	CFLAGS="$CFLAGS $accepted_flags"
	PAC_C_CHECK_COMPILER_OPTION($flag,accepted_flags="$accepted_flags $flag",)
        CFLAGS=$pcs_save_CFLAGS
    done
    pac_cc_strict_flags=$accepted_flags
fi
])

dnl/*D
dnl PAC_ARG_STRICT - Add --enable-strict to configure.  
dnl
dnl Synopsis:
dnl PAC_ARG_STRICT
dnl 
dnl Output effects:
dnl Adds '--enable-strict' to the command line.
dnl
dnl D*/
AC_DEFUN([PAC_ARG_STRICT],[
AC_ARG_ENABLE(strict,
[--enable-strict  - Turn on strict compilation testing when using gcc])
PAC_CC_STRICT($enable_strict)
CFLAGS="$CFLAGS $pac_cc_strict_flags"
export CFLAGS
])

dnl Return the integer structure alignment in pac_cv_c_max_integer_align
dnl Possible values include
dnl	packed
dnl	two
dnl	four
dnl	eight
dnl
dnl In addition, a "Could not determine alignment" and a "error!"
dnl return is possible.  
AC_DEFUN([PAC_C_MAX_INTEGER_ALIGN],[
AC_CACHE_CHECK([for max C struct integer alignment],
pac_cv_c_max_integer_align,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    int is_packed  = 1;
    int is_two     = 1;
    int is_four    = 1;
    int is_eight   = 1;
    struct { char a; int b; } char_int;
    struct { char a; short b; } char_short;
    struct { char a; long b; } char_long;
    struct { char a; int b; char c; } char_int_char;
    struct { char a; short b; char c; } char_short_char;
#ifdef HAVE_LONG_LONG_INT
    struct { long long int a; char b; } lli_c;
    struct { char a; long long int b; } c_lli;
#endif
    int size, extent, extent2;

    /* assume max integer alignment isn't 8 if we don't have
     * an eight-byte value :)
     */
#ifdef HAVE_LONG_LONG_INT
    if (sizeof(int) < 8 && sizeof(long) < 8 && sizeof(long long int) < 8)
	is_eight = 0;
#else
    if (sizeof(int) < 8 && sizeof(long) < 8) is_eight = 0;
#endif

    size = sizeof(char) + sizeof(int);
    extent = sizeof(char_int);
    if (size != extent) is_packed = 0;
    if ( (extent % 2) != 0) is_two = 0;
    if ( (extent % 4) != 0) is_four = 0;
    if (sizeof(int) == 8 && (extent % 8) != 0) is_eight = 0;
    DBG("char_int",size,extent);

    size = sizeof(char) + sizeof(short);
    extent = sizeof(char_short);
    if (size != extent) is_packed = 0;
    if ( (extent % 2) != 0) is_two = 0;
    if (sizeof(short) == 4 && (extent % 4) != 0) is_four = 0;
    if (sizeof(short) == 8 && (extent % 8) != 0) is_eight = 0;
    DBG("char_short",size,extent);

    size = sizeof(char) + sizeof(long);
    extent = sizeof(char_long);
    if (size != extent) is_packed = 0;
    if ( (extent % 2) != 0) is_two = 0;
    if ( (extent % 4) != 0) is_four = 0;
    if (sizeof(long) == 8 && (extent % 8) != 0) is_eight = 0;
    DBG("char_long",size,extent);

#ifdef HAVE_LONG_LONG_INT
    size = sizeof(char) + sizeof(long long int);
    extent = sizeof(lli_c);
    extent2 = sizeof(c_lli);
    if (size != extent) is_packed = 0;
    if ( (extent % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(long long int) >= 8 && (extent % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
#endif

    size = sizeof(char) + sizeof(int) + sizeof(char);
    extent = sizeof(char_int_char);
    if (size != extent) is_packed = 0;
    if ( (extent % 2) != 0) is_two = 0;
    if ( (extent % 4) != 0) is_four = 0;
    if (sizeof(int) == 8 && (extent % 8) != 0) is_eight = 0;
    DBG("char_int_char",size,extent);

    size = sizeof(char) + sizeof(short) + sizeof(char);
    extent = sizeof(char_short_char);
    if (size != extent) is_packed = 0;
    if ( (extent % 2) != 0) is_two = 0;
    if (sizeof(short) == 4 && (extent % 4) != 0) is_four = 0;
    if (sizeof(short) == 8 && (extent % 8) != 0) is_eight = 0;
    DBG("char_short_char",size,extent);

    /* If aligned mod 8, it will be aligned mod 4 */
    if (is_eight) { is_four = 0; is_two = 0; }

    if (is_four) is_two = 0;

    /* Tabulate the results */
    cf = fopen( "ctest.out", "w" );
    if (is_packed + is_two + is_four + is_eight == 0) {
	fprintf( cf, "Could not determine alignment\n" );
    }
    else {
	if (is_packed + is_two + is_four + is_eight != 1) {
	    fprintf( cf, "error!\n" );
	}
	else {
	    if (is_packed) fprintf( cf, "packed\n" );
	    if (is_two) fprintf( cf, "two\n" );
	    if (is_four) fprintf( cf, "four\n" );
	    if (is_eight) fprintf( cf, "eight\n" );
	}
    }
    fclose( cf );
    return 0;
}],
pac_cv_c_max_integer_align=`cat ctest.out`,
pac_cv_c_max_integer_align="unknown",
pac_cv_c_max_integer_align="$CROSS_ALIGN_STRUCT_INT")
rm -f ctest.out
])
if test -z "$pac_cv_c_max_integer_align" ; then
    pac_cv_c_max_integer_align="unknown"
fi
])

dnl Return the floating point structure alignment in
dnl pac_cv_c_max_fp_align.
dnl
dnl Possible values include:
dnl	packed
dnl	two
dnl	four
dnl	eight
dnl     sixteen
dnl
dnl In addition, a "Could not determine alignment" and a "error!"
dnl return is possible.  
AC_DEFUN([PAC_C_MAX_FP_ALIGN],[
AC_CACHE_CHECK([for max C struct floating point alignment],
pac_cv_c_max_fp_align,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    int is_packed  = 1;
    int is_two     = 1;
    int is_four    = 1;
    int is_eight   = 1;
    int is_sixteen = 1;
    struct { char a; float b; } char_float;
    struct { float b; char a; } float_char;
    struct { char a; double b; } char_double;
    struct { double b; char a; } double_char;
#ifdef HAVE_LONG_DOUBLE
    struct { char a; long double b; } char_long_double;
    struct { long double b; char a; } long_double_char;
    struct { long double a; int b; char c; } long_double_int_char;
#endif
    int size, extent1, extent2;

    size = sizeof(char) + sizeof(float);
    extent1 = sizeof(char_float);
    extent2 = sizeof(float_char);
    if (size != extent1) is_packed = 0;
    if ( (extent1 % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(float) == 8 && (extent1 % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
    DBG("char_float",size,extent1);

    size = sizeof(char) + sizeof(double);
    extent1 = sizeof(char_double);
    extent2 = sizeof(double_char);
    if (size != extent1) is_packed = 0;
    if ( (extent1 % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(double) == 8 && (extent1 % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
    DBG("char_double",size,extent1);

#ifdef HAVE_LONG_DOUBLE
    size = sizeof(char) + sizeof(long double);
    extent1 = sizeof(char_long_double);
    extent2 = sizeof(long_double_char);
    if (size != extent1) is_packed = 0;
    if ( (extent1 % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(long double) >= 8 && (extent1 % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
    if (sizeof(long double) > 8 && (extent1 % 16) != 0
	&& (extent2 % 16) != 0) is_sixteen = 0;
    DBG("char_long-double",size,extent1);

    extent1 = sizeof(long_double_int_char);
    if ( (extent1 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0) is_four = 0;
    if (sizeof(long double) >= 8 && (extent1 % 8) != 0)	is_eight = 0;
    if (sizeof(long double) > 8 && (extent1 % 16) != 0) is_sixteen = 0;
#else
    is_sixteen = 0;
#endif

    if (is_sixteen) { is_eight = 0; is_four = 0; is_two = 0; }

    if (is_eight) { is_four = 0; is_two = 0; }

    if (is_four) is_two = 0;

    /* Tabulate the results */
    cf = fopen( "ctest.out", "w" );
    if (is_packed + is_two + is_four + is_eight + is_sixteen == 0) {
	fprintf( cf, "Could not determine alignment\n" );
    }
    else {
	if (is_packed + is_two + is_four + is_eight + is_sixteen != 1) {
	    fprintf( cf, "error!\n" );
	}
	else {
	    if (is_packed) fprintf( cf, "packed\n" );
	    if (is_two) fprintf( cf, "two\n" );
	    if (is_four) fprintf( cf, "four\n" );
	    if (is_eight) fprintf( cf, "eight\n" );
	    if (is_sixteen) fprintf( cf, "sixteen\n" );
	}
    }
    fclose( cf );
    return 0;
}],
pac_cv_c_max_fp_align=`cat ctest.out`,
pac_cv_c_max_fp_align="unknown",
pac_cv_c_max_fp_align="$CROSS_ALIGN_STRUCT_FP")
rm -f ctest.out
])
if test -z "$pac_cv_c_max_fp_align" ; then
    pac_cv_c_max_fp_align="unknown"
fi
])

dnl Return the floating point structure alignment in
dnl pac_cv_c_max_double_fp_align.
dnl
dnl Possible values include:
dnl	packed
dnl	two
dnl	four
dnl	eight
dnl
dnl In addition, a "Could not determine alignment" and a "error!"
dnl return is possible.  
AC_DEFUN([PAC_C_MAX_DOUBLE_FP_ALIGN],[
AC_CACHE_CHECK([for max C struct alignment of structs with doubles],
pac_cv_c_max_double_fp_align,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    int is_packed  = 1;
    int is_two     = 1;
    int is_four    = 1;
    int is_eight   = 1;
    struct { char a; float b; } char_float;
    struct { float b; char a; } float_char;
    struct { char a; double b; } char_double;
    struct { double b; char a; } double_char;
    int size, extent1, extent2;

    size = sizeof(char) + sizeof(float);
    extent1 = sizeof(char_float);
    extent2 = sizeof(float_char);
    if (size != extent1) is_packed = 0;
    if ( (extent1 % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(float) == 8 && (extent1 % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
    DBG("char_float",size,extent1);

    size = sizeof(char) + sizeof(double);
    extent1 = sizeof(char_double);
    extent2 = sizeof(double_char);
    if (size != extent1) is_packed = 0;
    if ( (extent1 % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(double) == 8 && (extent1 % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
    DBG("char_double",size,extent1);

    if (is_eight) { is_four = 0; is_two = 0; }

    if (is_four) is_two = 0;

    /* Tabulate the results */
    cf = fopen( "ctest.out", "w" );
    if (is_packed + is_two + is_four + is_eight == 0) {
	fprintf( cf, "Could not determine alignment\n" );
    }
    else {
	if (is_packed + is_two + is_four + is_eight != 1) {
	    fprintf( cf, "error!\n" );
	}
	else {
	    if (is_packed) fprintf( cf, "packed\n" );
	    if (is_two) fprintf( cf, "two\n" );
	    if (is_four) fprintf( cf, "four\n" );
	    if (is_eight) fprintf( cf, "eight\n" );
	}
    }
    fclose( cf );
    return 0;
}],
pac_cv_c_max_double_fp_align=`cat ctest.out`,
pac_cv_c_max_double_fp_align="unknown",
pac_cv_c_max_double_fp_align="$CROSS_ALIGN_STRUCT_DOUBLE_FP")
rm -f ctest.out
])
if test -z "$pac_cv_c_max_double_fp_align" ; then
    pac_cv_c_max_double_fp_align="unknown"
fi
])
AC_DEFUN([PAC_C_MAX_LONGDOUBLE_FP_ALIGN],[
AC_CACHE_CHECK([for max C struct floating point alignment with long doubles],
pac_cv_c_max_longdouble_fp_align,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    int is_packed  = 1;
    int is_two     = 1;
    int is_four    = 1;
    int is_eight   = 1;
    int is_sixteen = 1;
    struct { char a; long double b; } char_long_double;
    struct { long double b; char a; } long_double_char;
    struct { long double a; int b; char c; } long_double_int_char;
    int size, extent1, extent2;

    size = sizeof(char) + sizeof(long double);
    extent1 = sizeof(char_long_double);
    extent2 = sizeof(long_double_char);
    if (size != extent1) is_packed = 0;
    if ( (extent1 % 2) != 0 && (extent2 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0 && (extent2 % 4) != 0) is_four = 0;
    if (sizeof(long double) >= 8 && (extent1 % 8) != 0 && (extent2 % 8) != 0)
	is_eight = 0;
    if (sizeof(long double) > 8 && (extent1 % 16) != 0
	&& (extent2 % 16) != 0) is_sixteen = 0;
    DBG("char_long-double",size,extent1);

    extent1 = sizeof(long_double_int_char);
    if ( (extent1 % 2) != 0) is_two = 0;
    if ( (extent1 % 4) != 0) is_four = 0;
    if (sizeof(long double) >= 8 && (extent1 % 8) != 0)	is_eight = 0;
    if (sizeof(long double) > 8 && (extent1 % 16) != 0) is_sixteen = 0;

    if (is_sixteen) { is_eight = 0; is_four = 0; is_two = 0; }

    if (is_eight) { is_four = 0; is_two = 0; }

    if (is_four) is_two = 0;

    /* Tabulate the results */
    cf = fopen( "ctest.out", "w" );
    if (is_packed + is_two + is_four + is_eight + is_sixteen == 0) {
	fprintf( cf, "Could not determine alignment\n" );
    }
    else {
	if (is_packed + is_two + is_four + is_eight + is_sixteen != 1) {
	    fprintf( cf, "error!\n" );
	}
	else {
	    if (is_packed) fprintf( cf, "packed\n" );
	    if (is_two) fprintf( cf, "two\n" );
	    if (is_four) fprintf( cf, "four\n" );
	    if (is_eight) fprintf( cf, "eight\n" );
	    if (is_sixteen) fprintf( cf, "sixteen\n" );
	}
    }
    fclose( cf );
    return 0;
}],
pac_cv_c_max_longdouble_fp_align=`cat ctest.out`,
pac_cv_c_max_longdouble_fp_align="unknown",
pac_cv_c_max_longdouble_fp_align="$CROSS_ALIGN_STRUCT_LONGDOUBLE_FP")
rm -f ctest.out
])
if test -z "$pac_cv_c_max_longdouble_fp_align" ; then
    pac_cv_c_max_longdouble_fp_align="unknown"
fi
])

dnl Other tests assume that there is potentially a maximum alignment
dnl and that if there is no maximum alignment, or a type is smaller than
dnl that value, then we align on the size of the value, with the exception
dnl of the "position-based alignment" rules we test for separately.
dnl
dnl It turns out that these assumptions have fallen short in at least one
dnl case, on MacBook Pros, where doubles are aligned on 4-byte boundaries
dnl even when long doubles are aligned on 16-byte boundaries. So this test
dnl is here specifically to handle this case.
dnl
dnl Puts result in pac_cv_c_double_alignment_exception.
dnl
dnl Possible values currently include no and four.
dnl
AC_DEFUN([PAC_C_DOUBLE_ALIGNMENT_EXCEPTION],[
AC_CACHE_CHECK([if double alignment breaks rules, find actual alignment],
pac_cv_c_double_alignment_exception,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    struct { char a; double b; } char_double;
    struct { double b; char a; } double_char;
    int extent1, extent2, align_4 = 0;

    extent1 = sizeof(char_double);
    extent2 = sizeof(double_char);

    /* we're interested in the largest value, will let separate test
     * deal with position-based issues.
     */
    if (extent1 < extent2) extent1 = extent2;
    if ((sizeof(double) == 8) && (extent1 % 8) != 0) {
       if (extent1 % 4 == 0) {
#ifdef HAVE_MAX_FP_ALIGNMENT
          if (HAVE_MAX_FP_ALIGNMENT >= 8) align_4 = 1;
#else
          align_4 = 1;
#endif
       }
    }

    cf = fopen( "ctest.out", "w" );

    if (align_4) fprintf( cf, "four\n" );
    else fprintf( cf, "no\n" );

    fclose( cf );
    return 0;
}],
pac_cv_c_double_alignment_exception=`cat ctest.out`,
pac_cv_c_double_alignment_exception="unknown",
pac_cv_c_double_alignment_exception="$CROSS_ALIGN_DOUBLE_EXCEPTION")
rm -f ctest.out
])
if test -z "$pac_cv_c_double_alignment_exception" ; then
    pac_cv_c_double_alignment_exception="unknown"
fi
])

dnl Test for odd struct alignment rule that only applies max.
dnl padding when double value is at front of type.
dnl Puts result in pac_cv_c_double_pos_align.
dnl
dnl Search for "Power alignment mode" for more details.
dnl
dnl Possible values include yes, no, and unknown.
dnl
AC_DEFUN([PAC_C_DOUBLE_POS_ALIGN],[
AC_CACHE_CHECK([if alignment of structs with doubles is based on position],
pac_cv_c_double_pos_align,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    int padding_varies_by_pos = 0;
    struct { char a; double b; } char_double;
    struct { double b; char a; } double_char;
    int extent1, extent2;

    extent1 = sizeof(char_double);
    extent2 = sizeof(double_char);
    if (extent1 != extent2) padding_varies_by_pos = 1;

    cf = fopen( "ctest.out", "w" );
    if (padding_varies_by_pos) fprintf( cf, "yes\n" );
    else fprintf( cf, "no\n" );

    fclose( cf );
    return 0;
}],
pac_cv_c_double_pos_align=`cat ctest.out`,
pac_cv_c_double_pos_align="unknown",
pac_cv_c_double_pos_align="$CROSS_ALIGN_DOUBLE_POS")
rm -f ctest.out
])
if test -z "$pac_cv_c_double_pos_align" ; then
    pac_cv_c_double_pos_align="unknown"
fi
])

dnl Test for odd struct alignment rule that only applies max.
dnl padding when long long int value is at front of type.
dnl Puts result in pac_cv_c_llint_pos_align.
dnl
dnl Search for "Power alignment mode" for more details.
dnl
dnl Possible values include yes, no, and unknown.
dnl
AC_DEFUN([PAC_C_LLINT_POS_ALIGN],[
AC_CACHE_CHECK([if alignment of structs with long long ints is based on position],
pac_cv_c_llint_pos_align,[
AC_TRY_RUN([
#include <stdio.h>
#define DBG(a,b,c)
int main( int argc, char *argv[] )
{
    FILE *cf;
    int padding_varies_by_pos = 0;
#ifdef HAVE_LONG_LONG_INT
    struct { char a; long long int b; } char_llint;
    struct { long long int b; char a; } llint_char;
    int extent1, extent2;

    extent1 = sizeof(char_llint);
    extent2 = sizeof(llint_char);
    if (extent1 != extent2) padding_varies_by_pos = 1;
#endif

    cf = fopen( "ctest.out", "w" );
    if (padding_varies_by_pos) fprintf( cf, "yes\n" );
    else fprintf( cf, "no\n" );

    fclose( cf );
    return 0;
}],
pac_cv_c_llint_pos_align=`cat ctest.out`,
pac_cv_c_llint_pos_align="unknown",
pac_cv_c_llint_pos_align="$CROSS_ALIGN_LLINT_POS")
rm -f ctest.out
])
if test -z "$pac_cv_c_llint_pos_align" ; then
    pac_cv_c_llint_pos_align="unknown"
fi
])

dnl/*D
dnl PAC_FUNC_NEEDS_DECL - Set NEEDS_<funcname>_DECL if a declaration is needed
dnl
dnl Synopsis:
dnl PAC_FUNC_NEEDS_DECL(headerfiles,funcname)
dnl
dnl Output Effect:
dnl Sets 'NEEDS_<funcname>_DECL' if 'funcname' is not declared by the 
dnl headerfiles.
dnl
dnl Approach:
dnl Try to compile a program with the function, but passed with an incorrect
dnl calling sequence.  If the compilation fails, then the declaration
dnl is provided within the header files.  If the compilation succeeds,
dnl the declaration is required.
dnl
dnl We use a 'double' as the first argument to try and catch varargs
dnl routines that may use an int or pointer as the first argument.
dnl
dnl There is one difficulty - if the compiler has been instructed to
dnl fail on implicitly defined functions, then this test will always
dnl fail.
dnl 
dnl D*/
AC_DEFUN([PAC_FUNC_NEEDS_DECL],[
AC_CACHE_CHECK([whether $2 needs a declaration],
pac_cv_func_decl_$2,[
AC_TRY_COMPILE([$1
int $2(double, int, double, const char *);],[int a=$2(1.0,27,1.0,"foo");],
pac_cv_func_decl_$2=yes,pac_cv_func_decl_$2=no)])
if test "$pac_cv_func_decl_$2" = "yes" ; then
changequote(<<,>>)dnl
define(<<PAC_FUNC_NAME>>, translit(NEEDS_$2_DECL, [a-z *], [A-Z__]))dnl
changequote([, ])dnl
    AC_DEFINE_UNQUOTED(PAC_FUNC_NAME,1,[Define if $2 needs a declaration])
undefine([PAC_FUNC_NAME])
fi
])

dnl PAC_C_GNU_ATTRIBUTE - See if the GCC __attribute__ specifier is allow.
dnl Use the following
dnl #ifndef HAVE_GCC_ATTRIBUTE
dnl #define __attribute__(a)
dnl #endif
dnl If *not*, define __attribute__(a) as null
dnl
dnl We start by requiring Gcc.  Some other compilers accept __attribute__
dnl but generate warning messages, or have different interpretations 
dnl (which seems to make __attribute__ just as bad as #pragma) 
dnl For example, the Intel icc compiler accepts __attribute__ and
dnl __attribute__((pure)) but generates warnings for __attribute__((format...))
dnl
AC_DEFUN([PAC_C_GNU_ATTRIBUTE],[
AC_REQUIRE([AC_PROG_CC_GNU])
if test "$ac_cv_prog_gcc" = "yes" ; then
    AC_CACHE_CHECK([whether __attribute__ allowed],
pac_cv_gnu_attr_pure,[
AC_TRY_COMPILE([int foo(int) __attribute__ ((pure));],[int a;],
pac_cv_gnu_attr_pure=yes,pac_cv_gnu_attr_pure=no)])
AC_CACHE_CHECK([whether __attribute__((format)) allowed],
pac_cv_gnu_attr_format,[
AC_TRY_COMPILE([int foo(char *,...) __attribute__ ((format(printf,1,2)));],[int a;],
pac_cv_gnu_attr_format=yes,pac_cv_gnu_attr_format=no)])
    if test "$pac_cv_gnu_attr_pure" = "yes" -a "$pac_cv_gnu_attr_format" = "yes" ; then
        AC_DEFINE(HAVE_GCC_ATTRIBUTE,1,[Define if GNU __attribute__ is supported])
    fi
fi
])
dnl
dnl Check for a broken install (fails to preserve file modification times,
dnl thus breaking libraries.
dnl
dnl Create a library, install it, and then try to link against it.
AC_DEFUN([PAC_PROG_INSTALL_BREAKS_LIBS],[
AC_CACHE_CHECK([whether install breaks libraries],
ac_cv_prog_install_breaks_libs,[
AC_REQUIRE([AC_PROG_RANLIB])
AC_REQUIRE([AC_PROG_INSTALL])
AC_REQUIRE([AC_PROG_CC])
ac_cv_prog_install_breaks_libs=yes
# This is needed for Mac OSX 10.5
rm -rf conftest.dSYM
rm -f libconftest* conftest*
echo 'int foo(int);int foo(int a){return a;}' > conftest1.c
echo 'extern int foo(int); int main( int argc, char **argv){ return foo(0); }' > conftest2.c
if ${CC-cc} $CFLAGS -c conftest1.c >conftest.out 2>&1 ; then
    if ${AR-ar} cr libconftest.a conftest1.o >/dev/null 2>&1 ; then
        if ${RANLIB-:} libconftest.a >/dev/null 2>&1 ; then
	    # Anything less than sleep 10, and Mac OS/X (Darwin) 
	    # will claim that install works because ranlib won't complain
	    sleep 10
	    libinstall="$INSTALL_DATA"
	    eval "libinstall=\"$libinstall\""
	    if ${libinstall} libconftest.a libconftest1.a  >/dev/null 2>&1 ; then
                if ${CC-cc} $CFLAGS -o conftest conftest2.c $LDFLAGS libconftest1.a >>conftest.out 2>&1 && test -x conftest ; then
		    # Success!  Install works
 	            ac_cv_prog_install_breaks_libs=no
	        else
	            # Failure!  Does install -p work?	
		    rm -f libconftest1.a
		    if ${libinstall} -p libconftest.a libconftest1.a >/dev/null 2>&1 ; then
                        if ${CC-cc} $CFLAGS -o conftest conftest2.c $LDFLAGS libconftest1.a >>conftest.out 2>&1 && test -x conftest ; then
			# Success!  Install works
			    ac_cv_prog_install_breaks_libs="no, with -p"
			fi
		    fi
                fi
            fi
        fi
    fi
fi
# This is needed for Mac OSX 10.5
rm -rf conftest.dSYM
rm -f conftest* libconftest*])

if test -z "$RANLIB_AFTER_INSTALL" ; then
    RANLIB_AFTER_INSTALL=no
fi
case "$ac_cv_prog_install_breaks_libs" in
	yes)
	    RANLIB_AFTER_INSTALL=yes
	;;
	"no, with -p")
	    INSTALL_DATA="$INSTALL_DATA -p"
	;;
	*)
	# Do nothing
	:
	;;
esac
AC_SUBST(RANLIB_AFTER_INSTALL)
])

#
# determine if the compiler defines a symbol containing the function name
# Inspired by checks within the src/mpid/globus/configure.in file in MPICH2
#
# These tests check not only that the compiler defines some symbol, such
# as __FUNCTION__, but that the symbol correctly names the function.
#
# Defines 
#   HAVE__FUNC__      (if __func__ defined)
#   HAVE_CAP__FUNC__  (if __FUNC__ defined)
#   HAVE__FUNCTION__  (if __FUNCTION__ defined)
#
AC_DEFUN([PAC_CC_FUNCTION_NAME_SYMBOL],[
AC_CACHE_CHECK([whether the compiler defines __func__],
pac_cv_have__func__,[
tmp_am_cross=no
AC_RUN_IFELSE([
#include <string.h>
int foo(void);
int foo(void)
{
    return (strcmp(__func__, "foo") == 0);
}
int main(int argc, char ** argv)
{
    return (foo() ? 0 : 1);
}
], pac_cv_have__func__=yes, pac_cv_have__func__=no,tmp_am_cross=yes)
if test "$tmp_am_cross" = yes ; then
    AC_LINK_IFELSE([
#include <string.h>
int foo(void);
int foo(void)
{
    return (strcmp(__func__, "foo") == 0);
}
int main(int argc, char ** argv)
{
    return (foo() ? 0 : 1);
}
], pac_cv_have__func__=yes, pac_cv_have__func__=no)
fi
])

if test "$pac_cv_have__func__" = "yes" ; then
    AC_DEFINE(HAVE__FUNC__,,[define if the compiler defines __func__])
fi

AC_CACHE_CHECK([whether the compiler defines __FUNC__],
pac_cv_have_cap__func__,[
tmp_am_cross=no
AC_RUN_IFELSE([
#include <string.h>
int foo(void);
int foo(void)
{
    return (strcmp(__FUNC__, "foo") == 0);
}
int main(int argc, char ** argv)
{
    return (foo() ? 0 : 1);
}
], pac_cv_have_cap__func__=yes, pac_cv_have_cap__func__=no,tmp_am_cross=yes)
if test "$tmp_am_cross" = yes ; then
    AC_LINK_IFELSE([
#include <string.h>
int foo(void);
int foo(void)
{
    return (strcmp(__FUNC__, "foo") == 0);
}
int main(int argc, char ** argv)
{
    return (foo() ? 0 : 1);
}
], pac_cv_have__func__=yes, pac_cv_have__func__=no)
fi
])

if test "$pac_cv_have_cap__func__" = "yes" ; then
    AC_DEFINE(HAVE_CAP__FUNC__,,[define if the compiler defines __FUNC__])
fi

AC_CACHE_CHECK([whether the compiler sets __FUNCTION__],
pac_cv_have__function__,[
tmp_am_cross=no
AC_RUN_IFELSE([
#include <string.h>
int foo(void);
int foo(void)
{
    return (strcmp(__FUNCTION__, "foo") == 0);
}
int main(int argc, char ** argv)
{
    return (foo() ? 0 : 1);
}
], pac_cv_have__function__=yes, pac_cv_have__function__=no,tmp_am_cross=yes)
if test "$tmp_am_cross" = yes ; then
    AC_LINK_IFELSE([
#include <string.h>
int foo(void);
int foo(void)
{
    return (strcmp(__FUNCTION__, "foo") == 0);
}
int main(int argc, char ** argv)
{
    return (foo() ? 0 : 1);
}
], pac_cv_have__func__=yes, pac_cv_have__func__=no)
fi
])

if test "$pac_cv_have__function__" = "yes" ; then
    AC_DEFINE(HAVE__FUNCTION__,,[define if the compiler defines __FUNCTION__])
fi

])


dnl Check structure alignment
AC_DEFUN([PAC_STRUCT_ALIGNMENT],[
	# Initialize alignment checks
	is_packed=1
	is_two=1
	is_four=1
	is_eight=1
	is_largest=1

	# See if long double exists
	AC_TRY_COMPILE(,[long double a;],have_long_double=yes,have_long_double=no)

	# Get sizes of regular types
	AC_CHECK_SIZEOF(char)
	AC_CHECK_SIZEOF(int)
	AC_CHECK_SIZEOF(short)
	AC_CHECK_SIZEOF(long)
	AC_CHECK_SIZEOF(float)
	AC_CHECK_SIZEOF(double)
	AC_CHECK_SIZEOF(long double)

	# char_int comparison
	AC_CHECK_SIZEOF(char_int, 0, [typedef struct { char a; int b; } char_int; ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_int`
	extent=$ac_cv_sizeof_char_int
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_int`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "`expr $extent % 4`" != "0" ; then is_four=0 ; fi
	if test "$ac_cv_sizeof_int" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# char_short comparison
	AC_CHECK_SIZEOF(char_short, 0, [typedef struct { char a; short b; } char_short; ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_short`
	extent=$ac_cv_sizeof_char_short
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_short`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "$ac_cv_sizeof_short" = "4" -a "`expr $extent % 4`" != "0" ; then
	   is_four=0
	fi
	if test "$ac_cv_sizeof_short" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# char_long comparison
	AC_CHECK_SIZEOF(char_long, 0, [typedef struct { char a; long b; } char_long; ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_long`
	extent=$ac_cv_sizeof_char_long
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_long`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "`expr $extent % 4`" != "0" ; then is_four=0 ; fi
	if test "$ac_cv_sizeof_long" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# char_float comparison
	AC_CHECK_SIZEOF(char_float, 0, [typedef struct { char a; float b; } char_float; ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_float`
	extent=$ac_cv_sizeof_char_float
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_float`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "`expr $extent % 4`" != "0" ; then is_four=0 ; fi
	if test "$ac_cv_sizeof_float" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# char_double comparison
	AC_CHECK_SIZEOF(char_double, 0, [typedef struct { char a; double b; } char_double; ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_double`
	extent=$ac_cv_sizeof_char_double
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_double`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "`expr $extent % 4`" != "0" ; then is_four=0 ; fi
	if test "$ac_cv_sizeof_double" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# char_long_double comparison
	if test "$have_long_double" = "yes"; then
	AC_CHECK_SIZEOF(char_long_double, 0, [
				       typedef struct {
				       	       char a;
					       long double b;
				       } char_long_double;
				       ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_long_double`
	extent=$ac_cv_sizeof_char_long_double
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_long_double`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "`expr $extent % 4`" != "0" ; then is_four=0 ; fi
	if test "$ac_cv_sizeof_long_double" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi
	fi

	# char_int_char comparison
	AC_CHECK_SIZEOF(char_int_char, 0, [
				       typedef struct {
				       	       char a;
					       int b;
					       char c;
				       } char_int_char;
				       ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_int + $ac_cv_sizeof_char`
	extent=$ac_cv_sizeof_char_int_char
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_int`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "`expr $extent % 4`" != "0" ; then is_four=0 ; fi
	if test "$ac_cv_sizeof_int" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# char_short_char comparison
	AC_CHECK_SIZEOF(char_short_char, 0, [
				       typedef struct {
				       	       char a;
					       short b;
					       char c;
				       } char_short_char;
				       ])
	size=`expr $ac_cv_sizeof_char + $ac_cv_sizeof_short + $ac_cv_sizeof_char`
	extent=$ac_cv_sizeof_char_short_char
	if test "$size" != "$extent" ; then is_packed=0 ; fi
	if test "`expr $extent % $ac_cv_sizeof_short`" != "0" ; then is_largest=0 ; fi
	if test "`expr $extent % 2`" != "0" ; then is_two=0 ; fi
	if test "$ac_cv_sizeof_short" = "4" -a "`expr $extent % 4`" != "0" ; then
	   is_four=0
	fi
	if test "$ac_cv_sizeof_short" = "8" -a "`expr $extent % 8`" != "0" ; then
	   is_eight=0
	fi

	# If aligned mod 8, it will be aligned mod 4
	if test $is_eight = 1 ; then is_four=0 ; is_two=0 ; fi
	if test $is_four = 1 ; then is_two=0 ; fi

	# Largest supersedes 8
	if test $is_largest = 1 ; then is_eight=0 ; fi

	# Find the alignment
	if test "`expr $is_packed + $is_largest + $is_two + $is_four + $is_eight`" = "0" ; then
	   pac_cv_struct_alignment="unknown"
	elif test "`expr $is_packed + $is_largest + $is_two + $is_four + $is_eight`" != "1" ; then
	   pac_cv_struct_alignment="unknown"
	elif test $is_packed = 1 ; then
	   pac_cv_struct_alignment="packed"
	elif test $is_largest = 1 ; then
	   pac_cv_struct_alignment="largest"
	elif test $is_two = 1 ; then
	   pac_cv_struct_alignment="two"
	elif test $is_four = 1 ; then
	   pac_cv_struct_alignment="four"
	elif test $is_eight = 1 ; then
	   pac_cv_struct_alignment="eight"
	fi
])

#
# AX_LLVM([ACTION-IF-FOUND,[ACTION-IF-NOT-FOUND]])
#
# If LLVM is successfully detected
# - Sets shell variable HAVE_LLVM='yes'
# - If ACTION-IF-FOUND is defined: Runs ACTION-IF-FOUND
# - If ACTION-IF-FOUND is undefined:
#   - Defines HAVE_LLVM.
#   - Defines LLVM_VERSION.
#   - Defines LLVM_BUILDMODE
#   - Defines LLVM_NDEBUG iff the LLVM library was compiled with NDEBUG.
#   - Sets shell variable LLVM_NDEBUG to 'yes' or 'no' correspondingly.
#
# If LLVM is not detected:
# - Sets shell variable HAVE_LLVM='no'
# - Runs ACTION-IF-NOT-FOUND if defined
#

AC_DEFUN([AX_LLVM],
[
  LLVMSEARCHPATH=$PATH
  AC_ARG_WITH([llvm],
              [AS_HELP_STRING([--with-llvm=PATH],[Specify path to root of llvm installation.])],
              [if test "x$withval" != "xyes"; then
                 LLVMSEARCHPATH="${withval%/}/bin"
               fi],
              [])

  ax_llvm_ok='yes'
  old_CXXFLAGS=$CXXFLAGS
  old_LDFLAGS=$LDFLAGS
  old_LIBS=$LIBS

  AC_LANG_PUSH([C++])
  AC_PATH_PROG([LLVMCONFIG],[llvm-config],[no],[$LLVMSEARCHPATH])

  if test "x$LLVMCONFIG" = "xno"; then
    ax_llvm_ok='no'
  fi

  if test "x$ax_llvm_ok" = "xyes"; then

    LLVMVERSION=`$LLVMCONFIG --version`
    LLVMBUILDMODE=`$LLVMCONFIG --build-mode`
    if test "x`echo $LLVMBUILDMODE | grep 'Asserts'`" = "x"; then
        LLVM_NDEBUG='yes'
    else
        LLVM_NDEBUG='no'
    fi

    CXXFLAGS="$CXXFLAGS `$LLVMCONFIG --cxxflags`"
    LLVMLDFLAGS=`$LLVMCONFIG --ldflags`
    LLVMLIBS=`$LLVMCONFIG --libs`
    SYSLIBS=`$LLVMCONFIG --system-libs 2>/dev/null`
    if test "x$?" = "x0"; then
      LLVMLDFLAGS="$LLVMLDFLAGS $SYSLIBS"
    fi
    for lib in $LLVMLDFLAGS; do
      if test "x`echo $lib | grep '^-l'`" != "x"; then
        lname=`echo "$lib" | sed s/^-l//`
        AC_CHECK_LIB([$lname],[main],[],[AC_MSG_FAILURE([Failed to find library $lib, required by LLVM.])])
      fi
    done
    LDFLAGS="$LDFLAGS $LLVMLDFLAGS"
    LIBS="$LIBS $LLVMLIBS"

    AC_MSG_CHECKING([for LLVM])

  fi

  AC_LANG_POP([C++])
  if test "x$ax_llvm_ok" = "xyes"; then
    AC_MSG_RESULT([$LLVMVERSION ($LLVMBUILDMODE)])
    ifelse([$1],,[AC_DEFINE([HAVE_LLVM],[1],[Define if there is a working LLVM library.])
                  AC_DEFINE_UNQUOTED([LLVM_VERSION],["$LLVMVERSION"],[Version of the LLVM library.])
                  AC_DEFINE_UNQUOTED([LLVM_BUILDMODE],["$LLVMBUILDMODE"],[Build mode of the LLVM library.])
                  if test "x$LLVM_NDEBUG" = "xyes"; then
                    AC_DEFINE([LLVM_NDEBUG],[1],[Define if LLVM was compiled with NDEBUG.])
                  fi
                 ],
                 [$1])
    HAVE_LLVM='yes'
  else
    AC_MSG_RESULT([no])
    CXXFLAGS=$old_CXXFLAGS
    LDFLAGS=$old_LDFLAGS
    LIBS=$old_LIBS
    $2
    HAVE_LLVM='no'
  fi
])

#!/bin/sh
# Generates BuildData.java
# Usage: gen_build_data.sh path/to/BuildData.java my.package.name
# Author: Benoit Sigoure (tsuna@stumbleupon.com)

# Fail entirely if any command fails.
set -e

DST=$1
PACKAGE=$2
CLASS=`basename "$1" .java`

fatal() {
  echo >&2 "$0: error: $*."
  exit 1
}

[ -n "$DST" ] || fatal 'missing destination path'
[ -n "$PACKAGE" ] || fatal 'missing package name'
[ -n "$CLASS" ] || fatal 'bad destination path'

echo "Generating $DST"
# Make sure the directory where we'll put `$DST' exists.
dir=`dirname "$DST"`
mkdir -p "$dir"

TZ=UTC
export TZ
# Can't use the system `date' tool because it's not portable.
sh=`python <<EOF
import time
t = time.time();
print "timestamp=%d" % t;
print "date=%r" % time.strftime("%Y/%m/%d %T %z", time.gmtime(t))
EOF`
eval "$sh"  # Sets the timestamp and date variables.

user=`whoami`
host=`uname -n`
repo=`pwd`

sh=`git rev-list --pretty=format:%h HEAD --max-count=1 \
    | sed '1s/commit /full_rev=/;2s/^/short_rev=/'`
eval "$sh"  # Sets the full_rev & short_rev variables.

is_mint_repo() {
  git rev-parse --verify HEAD >/dev/null &&
  git update-index --refresh >/dev/null &&
  git diff-files --quiet &&
  git diff-index --cached --quiet HEAD
}

if is_mint_repo; then
  repo_status='MINT'
else
  repo_status='MODIFIED'
fi

cat >"$DST" <<EOF
/* This file was generated by $0.  Do not edit manually.  */
package $PACKAGE;

/** Build data for {@code $PACKAGE} */
public final class $CLASS {
  /** Short revision at which this package was built. */
  public static final String short_revision = "$short_rev";
  /** Full revision at which this package was built. */
  public static final String full_revision = "$full_rev";
  /** UTC date at which this package was built. */
  public static final String date = "$date";
  /** UNIX timestamp of the time of the build. */
  public static final long timestamp = $timestamp;

  /** Represents the status of the repository at the time of the build. */
  public static enum RepoStatus {
    /** The status of the repository was unknown at the time of the build. */
    UNKNOWN,
    /** There was no local modification during the build. */
    MINT,
    /** There were some local modifications during the build. */
    MODIFIED;
  }
  /** Status of the repository at the time of the build. */
  public static final RepoStatus repo_status = RepoStatus.$repo_status;

  /** Username of the user who built this package. */
  public static final String user = "$user";
  /** Host on which this package was built. */
  public static final String host = "$host";
  /** Path to the repository in which this package was built. */
  public static final String repo = "$repo";

  /** Human readable string describing the revision of this package. */
  public static final String revisionString() {
    return "$PACKAGE built at revision $short_rev ($repo_status)";
  }
  /** Human readable string describing the build information of this package. */
  public static final String buildString() {
    return "Built on $date by $user@$host:$repo";
  }

  // These functions are useful to avoid cross-jar inlining.

  /** Short revision at which this package was built. */
  public static String shortRevision() {
    return short_revision;
  }
  /** Full revision at which this package was built. */
  public static String fullRevision() {
    return full_revision;
  }
  /** UTC date at which this package was built. */
  public static String date() {
    return date;
  }
  /** UNIX timestamp of the time of the build. */
  public static long timestamp() {
    return timestamp;
  }
  /** Status of the repository at the time of the build. */
  public static RepoStatus repoStatus() {
    return repo_status;
  }
  /** Username of the user who built this package. */
  public static String user() {
    return user;
  }
  /** Host on which this package was built. */
  public static String host() {
    return host;
  }
  /** Path to the repository in which this package was built. */
  public static String repo() {
    return repo;
  }

  // Can't instantiate.
  private $CLASS() {}
}
EOF

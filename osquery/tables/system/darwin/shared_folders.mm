/*
 *  Copyright (c) 2017-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed in accordance with the terms specified in
 *  the LICENSE file found in the root directory of this source tree.
 */

#import <OpenDirectory/OpenDirectory.h>

#include <osquery/core.h>
#include <osquery/filesystem/filesystem.h>
#include <osquery/logger.h>
#include <osquery/tables.h>

namespace osquery {
namespace tables {

QueryData genSharedFolders(QueryContext &context) {
  QueryData results;

  @autoreleasepool {
    ODSession* s = [ODSession defaultSession];
    NSError* err = nullptr;
    ODNode* root = [ODNode nodeWithSession:s name:@"/Local/Default" error:&err];
    if (err != nullptr) {
      TLOG << "Error with OpenDirectory node: "
           << std::string([[err localizedDescription] UTF8String]);
    }

    ODQuery* q = [ODQuery queryWithNode:root
                         forRecordTypes:kODRecordTypeSharePoints
                              attribute:@"dsAttrTypeNative:directory_path"
                              matchType:kODMatchEqualTo
                            queryValues:nil
                       returnAttributes:kODAttributeTypeNativeOnly
                         maximumResults:0
                                  error:&err];
    if (err != nullptr) {
      TLOG << "Error with OpenDirectory query: "
           << std::string([[err localizedDescription] UTF8String]);
    }

    // Obtain the results synchronously, not good for very large sets.
    NSArray* od_results = [q resultsAllowingPartial:NO error:&err];
    if (err != nullptr) {
      TLOG << "Error with OpenDirectory results: "
           << std::string([[err localizedDescription] UTF8String]);
    }

    for (ODRecord* re in od_results) {
      NSDictionary* recordPath = [re recordDetailsForAttributes:nil error:&err];
      Row r;

      if (err != nullptr) {
        TLOG << "Error with OpenDirectory attribute: "
             << std::string([[err localizedDescription] UTF8String]);
      } else {
        auto nameValue = [[[recordPath valueForKey:@"dsAttrTypeNative:smb_name"]
            lastObject] UTF8String];
        auto pathValue =
            [[[recordPath valueForKey:@"dsAttrTypeNative:directory_path"]
                lastObject] UTF8String];
        r["name"] = nameValue;
        r["path"] = pathValue;
        results.push_back(r);
      }
    }
  }
  return results;
}

} // namespace tables
} // namespace osquery

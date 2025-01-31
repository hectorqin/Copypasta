#import <Cephei/HBPreferences.h>
#import "CPAManager.h"

@implementation CPAManager

+(instancetype)sharedInstance {
    static CPAManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [CPAManager alloc];
        sharedInstance.numberOfItems = 10;
        [sharedInstance reload];
    });
    return sharedInstance;
}

-(id)init {
    return [CPAManager sharedInstance];
}

-(void)reload {
    if (!_items) _items = [NSMutableArray new];
    if (!_favoriteItems) _favoriteItems = [NSMutableArray new];

    [_items removeAllObjects];
    [_favoriteItems removeAllObjects];

    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.copypasta-items"];

    if ([file objectForKey:@"items"] && [[file objectForKey:@"items"] isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in [file objectForKey:@"items"]) {
            [_items addObject:[CPAItem itemWithContent:item[@"content"] title:item[@"title"] bundleId:item[@"bundleId"]]];
        }
    }

    if ([file objectForKey:@"favoriteItems"] && [[file objectForKey:@"favoriteItems"] isKindOfClass:[NSArray class]]) {
        for (NSDictionary *item in [file objectForKey:@"favoriteItems"]) {
            [_favoriteItems addObject:[CPAItem itemWithContent:item[@"content"] title:item[@"title"] bundleId:item[@"bundleId"]]];
        }
    }
}

-(NSArray*)items {
    return _items;
}

-(NSArray*)favoriteItems {
    return _favoriteItems;
}

-(void)addItem:(CPAItem *)item {
    NSLog(@"__COPYPASTA__  addItem %@", item.content);
    if ([_items count] >= 1) {
        int index = [_items count] - 1;
        CPAItem *lastItem = [_items objectAtIndex:index];
        // 与上次内容相同，则仅更新 title 和 bundleId
        if ([lastItem.content isEqualToString:item.content]) {
            lastItem.title = item.title;
            lastItem.bundleId = item.bundleId;
            [_items replaceObjectAtIndex:index withObject:lastItem];
            [self save];
            return;
        }
    }
    if ([_items count] >= self.numberOfItems) {
        [_items removeObjectsInRange:NSMakeRange(self.numberOfItems - 1, [_items count] - self.numberOfItems + 1)];
    }

    [_items insertObject:item atIndex:0];
    [self save];
}

-(void)removeItem:(CPAItem *)item {
    NSLog(@"__COPYPASTA__  removeItem %@", item.content);
    [_items removeObject:item];
    [_favoriteItems removeObject:item];
    [self save];
}

-(void)favoriteItem:(CPAItem *)item {
    NSLog(@"__COPYPASTA__  favoriteItem %@", item.content);
    [_items removeObject:item];
    [_favoriteItems insertObject:item atIndex:0];
    [self save];
}

-(void)save {
    HBPreferences *file = [[HBPreferences alloc] initWithIdentifier:@"me.nepeta.copypasta-items"];

    NSMutableArray *items = [NSMutableArray new];
    NSMutableArray *favoriteItems = [NSMutableArray new];

    for (CPAItem *item in _items) {
        [items addObject:@{
          @"content": item.content ?: @"",
          @"title": item.title ?: @"",
          @"bundleId": item.bundleId ?: @""
        }];
    }

    for (CPAItem *item in _favoriteItems) {
        [favoriteItems addObject:@{
          @"content": item.content ?: @"",
          @"title": item.title ?: @"",
          @"bundleId": item.bundleId ?: @""
        }];
    }

    [file setObject:items forKey:@"items"];
    [file setObject:favoriteItems forKey:@"favoriteItems"];
    [file synchronize];

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (CFStringRef)@"me.nepeta.copypasta/ReloadItems", nil, nil, true);
}

@end
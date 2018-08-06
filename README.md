# RxCacheable
RxSwift Caching Utillities

I have been working on a couple of simple extensions for data caching with Rx and I would be interested in any comments on these.  e.g. if there is already some way to achieve the effect with a combination of built-in operators or, alternately, if anyone thinks these would be useful as proper Traits.

The two classes are:

`CachedSingle`

This serves as a read-through cache backed by a Single data source.  New subscriptions prompt an expiration check and new subscribers can be configured to either block waiting for updated data or receive the current replay value followed by the update.

`TransformableCachedSingle`

This provides a way to transform the cached data in the CachedSingle for a time and then allow those transformations to be removed when new data subsequently arrives from the Single producer.  This allows for making “optimistic” changes to local data that are held during the course of a transaction but then allowed to be overwritten when fresh data arrives later.

Example

I’m have a network API for status on a user.  I’m going to make a call that will attempt to change the status.  I want to show the change immediately in the client UI (in a consistent way throughout the app) but allow subsequent updates from the server to take precedence in a natural way that avoids race conditions with stale data.   The above utilities appear to make this easy, even when composing a view from multiple data sources.  I simply transform the status with the expected or indeterminate result and then confirm/rollback and expire the the transformation.



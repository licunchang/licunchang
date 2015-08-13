**File Name** http-cache-control-expires.md  

**Description** HTTP 协议中的 cache-control 和 expires      
**Author** LiCunchang(printf@live.com)   
**Version** 3.0.20130728  

------

## Cache-Control

`Cache-Control` 头部字段

注意：HTTP/1.0 中可能没有实现 `Cache-Control` 并且仅仅实现了 `Pragma: no-cache`。


The Cache-Control general-header field is used to specify directives
   that MUST be obeyed by all caching mechanisms along the
   request/response chain. The directives specify behavior intended to
   prevent caches from adversely interfering with the request or
   response. These directives typically override the default caching
   algorithms. Cache directives are unidirectional in that the presence
   of a directive in a request does not imply that the same directive is
   to be given in the response.

      Note that HTTP/1.0 caches might not implement Cache-Control and
      might only implement Pragma: no-cache (see section 14.32).


Cache-Control 字段的格式如下：

    Cache-Control   = "Cache-Control" ":" 1#cache-directive

    cache-directive = cache-request-directive
        | cache-response-directive

    cache-request-directive =
          "no-cache"                          
        | "no-store"                          
        | "max-age" "=" delta-seconds         
        | "max-stale" [ "=" delta-seconds ]   
        | "min-fresh" "=" delta-seconds       
        | "no-transform"                      
        | "only-if-cached"                    
        | cache-extension                     

    cache-response-directive =
          "public"                               
        | "private" [ "=" <"> 1#field-name <"> ] 
        | "no-cache" [ "=" <"> 1#field-name <"> ]
        | "no-store"                             
        | "no-transform"                         
        | "must-revalidate"                      
        | "proxy-revalidate"                     
        | "max-age" "=" delta-seconds            
        | "s-maxage" "=" delta-seconds           
        | cache-extension                        

    cache-extension = token [ "=" ( token | quoted-string ) ]







## See also

*  Character Set Support [http://dev.mysql.com/doc/refman/5.5/en/charset.html](http://dev.mysql.com/doc/refman/5.5/en/charset.html "Character Set Support")

## References

1. rfc2616, taobaodba, [http://www.ietf.org/rfc/rfc2616.txt](http://www.ietf.org/rfc/rfc2616.txt "rfc2616")












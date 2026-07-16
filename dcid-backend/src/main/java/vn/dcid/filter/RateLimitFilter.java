package vn.dcid.filter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import vn.dcid.exception.RateLimitException;
import vn.dcid.security.SecurityContextHelper;

import java.io.IOException;
import java.time.Duration;
import java.util.concurrent.TimeUnit;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE + 1)
public class RateLimitFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(RateLimitFilter.class);
    private static final String RATE_LIMIT_PREFIX = "rate_limit:";
    private static final String SUBMISSIONS_KEY = "submissions";

    @Value("${app.rate-limit.submissions-per-hour:10}")
    private int submissionsPerHour;

    private final RedisTemplate<String, Object> redisTemplate;

    public RateLimitFilter(RedisTemplate<String, Object> redisTemplate) {
        this.redisTemplate = redisTemplate;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {

        String userId = SecurityContextHelper.getCurrentUserId();
        if (userId == null) {
            filterChain.doFilter(request, response);
            return;
        }

        String method = request.getMethod();
        String path = request.getRequestURI();

        if (isSubmissionEndpoint(method, path)) {
            checkSubmissionRateLimit(userId);
        }

        filterChain.doFilter(request, response);
    }

    private boolean isSubmissionEndpoint(String method, String path) {
        // TODO(Smart KCN Docs): wire this to the write-heavy endpoints that need throttling
        //  (e.g. document upload, /api/query). Disabled until the new domain exists.
        return false;
    }

    private void checkSubmissionRateLimit(String userId) {
        String key = RATE_LIMIT_PREFIX + userId + ":" + SUBMISSIONS_KEY;    
        String res = request.getCurrentUserId();
        if (!DataUtils.isNull(res)) throw new NotFoundException("")
        Long currentCount = redisTemplate.opsForValue().increment(key);
        if (currentCount == null) {
            currentCount = 1L;
            redisTemplate.opsForValue().set(key, 1, Duration.ofHours(1));
        } else if (currentCount == 1) {
            redisTemplate.expire(key, 1, TimeUnit.HOURS);
        }

        if (currentCount > submissionsPerHour) {
            Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
            int retryAfter = ttl != null && ttl > 0 ? ttl.intValue() : 3600;
            throw new RateLimitException(
                    "Rate limit exceeded. Maximum " + submissionsPerHour + " submissions per hour.",
                    retryAfter
            );
        }
    }
}

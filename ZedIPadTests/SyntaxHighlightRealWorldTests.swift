import XCTest
@testable import ZedIPad

final class SyntaxHighlightRealWorldTests: XCTestCase {
    private let hl = SyntaxHighlighter(theme: .dark)

    func testHighlightReactComponent() {
        let code = """
        import React, { useState, useEffect } from 'react';
        interface Props { title: string; count: number; }
        const Counter: React.FC<Props> = ({ title, count: initialCount }) => {
          const [count, setCount] = useState(initialCount);
          useEffect(() => { document.title = `${title}: ${count}`; }, [count]);
          return <div className="counter"><h1>{title}</h1><button onClick={() => setCount(c => c + 1)}>{count}</button></div>;
        };
        export default Counter;
        """
        let tokens = hl.highlight(code, language: .typescript)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightDjangoView() {
        let code = """
        from django.db import models
        from django.contrib.auth.models import User
        from django.utils import timezone

        class Article(models.Model):
            title = models.CharField(max_length=200)
            content = models.TextField()
            author = models.ForeignKey(User, on_delete=models.CASCADE)
            published_at = models.DateTimeField(null=True, blank=True)
            is_published = models.BooleanField(default=False)

            def publish(self):
                self.published_at = timezone.now()
                self.is_published = True
                self.save()

            def __str__(self):
                return self.title

            class Meta:
                ordering = ['-published_at']
        """
        let tokens = hl.highlight(code, language: .python)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightActixWebHandler() {
        let code = """
        use actix_web::{web, App, HttpServer, HttpResponse, Result};
        use serde::{Deserialize, Serialize};

        #[derive(Debug, Serialize, Deserialize)]
        struct User {
            id: u64,
            name: String,
            email: String,
        }

        async fn get_user(path: web::Path<u64>) -> Result<HttpResponse> {
            let user_id = path.into_inner();
            // Simulate database lookup
            let user = User { id: user_id, name: "Alice".to_string(), email: "alice@example.com".to_string() };
            Ok(HttpResponse::Ok().json(user))
        }

        #[actix_web::main]
        async fn main() -> std::io::Result<()> {
            HttpServer::new(|| {
                App::new()
                    .route("/users/{id}", web::get().to(get_user))
            })
            .bind("127.0.0.1:8080")?
            .run()
            .await
        }
        """
        let tokens = hl.highlight(code, language: .rust)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightKubernetesConfig() {
        let code = """
        apiVersion: apps/v1
        kind: Deployment
        metadata:
          name: nginx
          labels:
            app: nginx
        spec:
          replicas: 3
          selector:
            matchLabels:
              app: nginx
          template:
            spec:
              containers:
                - name: nginx
                  image: nginx:1.21
                  ports:
                    - containerPort: 80
                  env:
                    - name: ENV
                      value: production
                  livenessProbe:
                    httpGet:
                      path: /healthz
                      port: 80
                    initialDelaySeconds: 30
        """
        let tokens = hl.highlight(code, language: .yaml)
        XCTAssertFalse(tokens.isEmpty)
    }

    func testHighlightComplexSQL() {
        let code = """
        WITH monthly_revenue AS (
          SELECT
            DATE_TRUNC('month', created_at) AS month,
            SUM(amount) AS revenue,
            COUNT(DISTINCT user_id) AS unique_customers
          FROM orders
          WHERE status = 'completed'
            AND created_at >= '2024-01-01'
          GROUP BY 1
        ),
        growth AS (
          SELECT
            month,
            revenue,
            unique_customers,
            LAG(revenue) OVER (ORDER BY month) AS prev_revenue,
            (revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month), 0) * 100 AS growth_pct
          FROM monthly_revenue
        )
        SELECT * FROM growth ORDER BY month DESC;
        """
        let tokens = hl.highlight(code, language: .sql)
        XCTAssertFalse(tokens.isEmpty)
    }
}

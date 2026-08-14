package vn.dcid.service;

import io.minio.*;
import io.minio.http.Method;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.InputStream;
import java.util.concurrent.TimeUnit;

@Service
public class MinioService {

    private final MinioClient minioClient;
    private final String bucketName;

    public MinioService(MinioClient minioClient, @Value("${app.minio.bucket:dcid}") String bucketName) {
        this.minioClient = minioClient;
        this.bucketName = bucketName;
    }

    public String upload(String objectName, InputStream inputStream, long size, String contentType) {
        try {
            ensureBucket();
            PutObjectArgs args = PutObjectArgs.builder()
                    .bucket(bucketName)
                    .object(objectName)
                    .stream(inputStream, size, -1)
                    .contentType(contentType)
                    .build();

            minioClient.putObject(args);
            return objectName;
        } catch (Exception e) {
            throw new IllegalStateException("Lỗi upload file lên MinIO: " + e.getMessage(), e);
        }
    }

    public String upload(MultipartFile file, String objectName) {
        try {
            InputStream inputStream = file.getInputStream();
            long size = file.getSize();
            String contentType = file.getContentType();

            return upload(objectName, inputStream, size, contentType);
        } catch (Exception e) {
            throw new IllegalStateException("Lỗi upload file lên MinIO: " + e.getMessage(), e);
        }
    }

    public String getPresignedUrl(String objectName, int expirySeconds) {
        try {
            return minioClient.getPresignedObjectUrl(
                    GetPresignedObjectUrlArgs.builder()
                            .method(Method.GET)
                            .bucket(bucketName)
                            .object(objectName)
                            .expiry(expirySeconds, TimeUnit.SECONDS)
                            .build()
            );
        } catch (Exception e) {
            throw new IllegalStateException("Lỗi tạo presigned URL: " + e.getMessage(), e);
        }
    }

    public void delete(String objectName) {
        try {
            minioClient.removeObject(
                    RemoveObjectArgs.builder()
                            .bucket(bucketName)
                            .object(objectName)
                            .build()
            );
        } catch (Exception e) {
            throw new IllegalStateException("Lỗi xóa file khỏi MinIO: " + e.getMessage(), e);
        }
    }

    public InputStream download(String objectName) {
        try {
            return minioClient.getObject(
                    GetObjectArgs.builder()
                            .bucket(bucketName)
                            .object(objectName)
                            .build()
            );
        } catch (Exception e) {
            throw new IllegalStateException("Lỗi tải file từ MinIO: " + e.getMessage(), e);
        }
    }

    /** Tạo bucket nếu chưa có (idempotent) — để upload chạy được trên MinIO mới. */
    private void ensureBucket() {
        try {
            boolean exists = minioClient.bucketExists(
                    BucketExistsArgs.builder().bucket(bucketName).build());
            if (!exists) {
                minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
            }
        } catch (Exception e) {
            throw new IllegalStateException("Không thể tạo/kiểm tra MinIO bucket: " + bucketName, e);
        }
    }
}

-- Migration: Create avatars storage bucket and RLS policies
-- Date: 2026-10-24

-- 1. Create 'avatars' bucket in storage.buckets if not exists
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
    'avatars',
    'avatars',
    true,
    5242880, -- 5 MB
    ARRAY['image/jpeg', 'image/png', 'image/webp', 'image/jpg']
)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Storage RLS policies for avatars
-- Public read access to avatars
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Public Access Avatars'
    ) THEN
        CREATE POLICY "Public Access Avatars" ON storage.objects
            FOR SELECT USING (bucket_id = 'avatars');
    END IF;
END $$;

-- Authenticated users can insert their own avatar
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Authenticated Users Can Upload Avatars'
    ) THEN
        CREATE POLICY "Authenticated Users Can Upload Avatars" ON storage.objects
            FOR INSERT WITH CHECK (
                bucket_id = 'avatars' AND auth.role() = 'authenticated'
            );
    END IF;
END $$;

-- Authenticated users can update/upsert their avatar
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Authenticated Users Can Update Avatars'
    ) THEN
        CREATE POLICY "Authenticated Users Can Update Avatars" ON storage.objects
            FOR UPDATE USING (
                bucket_id = 'avatars' AND auth.role() = 'authenticated'
            );
    END IF;
END $$;

-- Authenticated users can delete their avatar
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies 
        WHERE schemaname = 'storage' AND tablename = 'objects' AND policyname = 'Authenticated Users Can Delete Avatars'
    ) THEN
        CREATE POLICY "Authenticated Users Can Delete Avatars" ON storage.objects
            FOR DELETE USING (
                bucket_id = 'avatars' AND auth.role() = 'authenticated'
            );
    END IF;
END $$;

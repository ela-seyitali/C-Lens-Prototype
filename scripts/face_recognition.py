#!/usr/bin/env python3
"""
Basit yüz tanıma servisi
Flutter uygulamasından method channel ile çağrılacak
"""

import sys
import json
import os
import cv2
import numpy as np

# DeepFace import'u try-except ile sarmalayalım
try:
    from deepface import DeepFace
    DEEPFACE_AVAILABLE = True
except ImportError:
    DEEPFACE_AVAILABLE = False
    print("DeepFace modülü bulunamadı. Basit yüz tespit modu kullanılacak.")

def detect_face_simple(image_path):
    """Basit yüz tespit (DeepFace olmadan)"""
    try:
        # OpenCV ile yüz tespit
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        
        # Görüntüyü yükle
        img = cv2.imread(image_path)
        if img is None:
            return {
                'success': False,
                'embedding': None,
                'message': 'Görüntü yüklenemedi'
            }
        
        # Gri tonlamaya çevir
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        
        # Yüz tespit et
        faces = face_cascade.detectMultiScale(gray, 1.1, 4)
        
        if len(faces) == 0:
            return {
                'success': False,
                'embedding': None,
                'message': 'Yüz tespit edilemedi'
            }
        
        # Basit embedding oluştur (yüz koordinatları ve özellikler)
        face = faces[0]  # İlk yüzü al
        x, y, w, h = face
        
        # Basit özellik vektörü oluştur
        embedding = [
            float(x), float(y), float(w), float(h),  # Yüz koordinatları
            float(w/h),  # En-boy oranı
            float(x + w/2), float(y + h/2),  # Merkez nokta
        ]
        
        # Daha uzun bir vektör oluştur (128 boyutlu)
        while len(embedding) < 128:
            embedding.append(0.0)
        
        return {
            'success': True,
            'embedding': embedding[:128],
            'message': 'Basit yüz embedding\'i oluşturuldu'
        }
    except Exception as e:
        return {
            'success': False,
            'embedding': None,
            'message': f'Basit yüz tespit hatası: {str(e)}'
        }

def create_face_embedding(image_path):
    """Tek bir görüntüden yüz embedding'i oluştur"""
    try:
        if not DEEPFACE_AVAILABLE:
            # DeepFace yoksa basit yüz tespit yap
            return detect_face_simple(image_path)
        
        # DeepFace ile embedding oluştur
        embedding = DeepFace.represent(
            img_path=image_path,
            model_name='Facenet',  # Varsayılan model
            enforce_detection=True
        )
        
        # Embedding listesini düzleştir (DeepFace liste döner)
        if isinstance(embedding, list) and len(embedding) > 0:
            embedding = embedding[0]['embedding']
        
        return {
            'success': True,
            'embedding': embedding,
            'message': 'Yüz embedding\'i başarıyla oluşturuldu'
        }
    except Exception as e:
        return {
            'success': False,
            'embedding': None,
            'message': f'Hata: {str(e)}'
        }

def compare_faces_simple(img1_path, img2_path):
    """Basit yüz karşılaştırma (DeepFace olmadan)"""
    try:
        # Her iki görüntüden de embedding al
        result1 = detect_face_simple(img1_path)
        result2 = detect_face_simple(img2_path)
        
        if not result1['success'] or not result2['success']:
            return {
                'success': False,
                'verified': False,
                'distance': 1.0,
                'threshold': 0.5,
                'confidence': 0.0,
                'message': 'Yüz tespit edilemedi'
            }
        
        # Basit kosinüs benzerliği hesapla
        embedding1 = np.array(result1['embedding'])
        embedding2 = np.array(result2['embedding'])
        
        # Kosinüs benzerliği
        dot_product = np.dot(embedding1, embedding2)
        norm1 = np.linalg.norm(embedding1)
        norm2 = np.linalg.norm(embedding2)
        
        if norm1 == 0 or norm2 == 0:
            similarity = 0
        else:
            similarity = dot_product / (norm1 * norm2)
        
        # Mesafe (1 - benzerlik)
        distance = 1.0 - similarity
        threshold = 0.3  # Basit eşik değeri
        verified = distance < threshold
        
        return {
            'success': True,
            'verified': verified,
            'distance': float(distance),
            'threshold': threshold,
            'confidence': float(similarity),
            'message': 'Basit yüz karşılaştırması tamamlandı'
        }
    except Exception as e:
        return {
            'success': False,
            'verified': False,
            'distance': 1.0,
            'threshold': 0.5,
            'confidence': 0.0,
            'message': f'Basit karşılaştırma hatası: {str(e)}'
        }

def verify_faces(img1_path, img2_path):
    """İki yüz görüntüsünü karşılaştır"""
    try:
        if not DEEPFACE_AVAILABLE:
            # DeepFace yoksa basit karşılaştırma yap
            return compare_faces_simple(img1_path, img2_path)
        
        result = DeepFace.verify(
            img1_path=img1_path,
            img2_path=img2_path,
            model_name='Facenet',
            distance_metric='cosine',  # Kosinüs mesafesi
            enforce_detection=True
        )
        
        return {
            'success': True,
            'verified': result['verified'],
            'distance': float(result['distance']),
            'threshold': float(result['threshold']),
            'confidence': 1.0 - float(result['distance']),
            'message': 'Yüz karşılaştırması başarılı'
        }
    except Exception as e:
        return {
            'success': False,
            'verified': False,
            'distance': 0.0,
            'threshold': 0.0,
            'confidence': 0.0,
            'message': f'Hata: {str(e)}'
        }

def detect_face(image_path):
    """Görüntüde yüz tespit et"""
    try:
        if not DEEPFACE_AVAILABLE:
            # DeepFace yoksa basit tespit yap
            result = detect_face_simple(image_path)
            return {
                'success': result['success'],
                'face_detected': result['success'],
                'face_count': 1 if result['success'] else 0,
                'message': result['message']
            }
        
        # Face detection yap
        faces = DeepFace.extract_faces(
            img_path=image_path,
            enforce_detection=True,
            detector_backend='opencv'
        )
        
        if len(faces) > 0:
            return {
                'success': True,
                'face_detected': True,
                'face_count': len(faces),
                'message': f'{len(faces)} yüz tespit edildi'
            }
        else:
            return {
                'success': False,
                'face_detected': False,
                'face_count': 0,
                'message': 'Yüz tespit edilemedi'
            }
    except Exception as e:
        return {
            'success': False,
            'face_detected': False,
            'face_count': 0,
            'message': f'Hata: {str(e)}'
        }

if __name__ == "__main__":
    """Konsoldan test için"""
    if len(sys.argv) < 2:
        print(json.dumps({
            'success': False,
            'message': 'Kullanım: python face_recognition.py <command> <params>'
        }))
        sys.exit(1)
    
    command = sys.argv[1]
    
    if command == 'embed':
        if len(sys.argv) < 3:
            result = {'success': False, 'message': 'Görüntü yolu gerekli'}
        else:
            image_path = sys.argv[2]
            result = create_face_embedding(image_path)
    
    elif command == 'verify':
        if len(sys.argv) < 4:
            result = {'success': False, 'message': 'İki görüntü yolu gerekli'}
        else:
            img1_path = sys.argv[2]
            img2_path = sys.argv[3]
            result = verify_faces(img1_path, img2_path)
    
    elif command == 'detect':
        if len(sys.argv) < 3:
            result = {'success': False, 'message': 'Görüntü yolu gerekli'}
        else:
            image_path = sys.argv[2]
            result = detect_face(image_path)
    
    else:
        result = {'success': False, 'message': 'Geçersiz komut'}
    
    print(json.dumps(result))


from rest_framework import serializers
from django.utils import timezone
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer
from django.contrib.auth import get_user_model
from .models import Eleve, PresenceRepas

User = get_user_model()


class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    """Serializer personnalisé pour inclure les infos utilisateur dans la réponse de login"""
    
    def validate(self, attrs):
        data = super().validate(attrs)
        
        # Ajouter les informations utilisateur
        user = self.user
        profile = getattr(user, 'profile', None)
        
        data['user'] = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name or '',
            'last_name': user.last_name or '',
            'role': profile.role if profile else 'prestataire',
            'contact': profile.contact if profile else None,
            'poste': profile.poste if profile else None,
        }
        
        return data


class StudentSerializer(serializers.ModelSerializer):
    """Serializer pour les élèves"""
    full_name = serializers.SerializerMethodField()
    classe_nom = serializers.CharField(source='classe.nom', read_only=True)

    class Meta:
        model = Eleve
        fields = [
            'id',
            'matricule',
            'nom',
            'prenom',
            'full_name',
            'classe',
            'classe_nom',
            'date_inscription',
            'actif',
            'contact_parent',
            'email_parent',
            'notes',
            'photo',
        ]
        read_only_fields = ['id', 'date_inscription']

    def get_full_name(self, obj):
        return f"{obj.prenom} {obj.nom}"


class AttendanceSerializer(serializers.ModelSerializer):
    """Serializer pour les présences"""
    student = StudentSerializer(source='eleve', read_only=True)
    student_id = serializers.IntegerField(source='eleve.id', read_only=True)
    notes = serializers.CharField(source='commentaire', required=False, allow_blank=True)

    class Meta:
        model = PresenceRepas
        fields = [
            'id',
            'student_id',
            'student',
            'eleve',  # Pour la création
            'date',
            'repas',
            'present',
            'notes',
            'commentaire',
            'heure_pointage',
            'menu',
        ]
        read_only_fields = ['id', 'heure_pointage']

    def create(self, validated_data):
        # S'assurer que la date est aujourd'hui si non fournie
        if 'date' not in validated_data or validated_data['date'] is None:
            validated_data['date'] = timezone.now().date()
        
        # Gérer le champ notes/commentaire
        if 'commentaire' in validated_data:
            validated_data['commentaire'] = validated_data.get('commentaire', '')
        
        return super().create(validated_data)

    def to_representation(self, instance):
        """Personnaliser la représentation pour correspondre à l'API Flutter"""
        representation = super().to_representation(instance)
        # Renommer commentaire en notes pour l'API
        if 'commentaire' in representation:
            representation['notes'] = representation.pop('commentaire')
        # Ajouter created_at et updated_at si nécessaire
        if hasattr(instance, 'created_at'):
            representation['created_at'] = instance.created_at.isoformat() if instance.created_at else None
        if hasattr(instance, 'updated_at'):
            representation['updated_at'] = instance.updated_at.isoformat() if instance.updated_at else None
        return representation

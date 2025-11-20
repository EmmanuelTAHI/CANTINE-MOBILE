from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework_simplejwt.views import TokenObtainPairView
from django.utils import timezone
from datetime import date

from .models import Eleve, PresenceRepas
from .serializers import StudentSerializer, AttendanceSerializer, CustomTokenObtainPairSerializer
from .models import MenuJournalier, MenuMensuel
from .serializers import MenuJournalierSerializer, MenuMensuelSerializer


class StudentViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des élèves.
    GET /api/students/ - Liste tous les élèves
    GET /api/students/:id/ - Détails d'un élève
    POST /api/students/ - Créer un élève (admin uniquement)
    PUT /api/students/:id/ - Modifier un élève (admin uniquement)
    DELETE /api/students/:id/ - Supprimer un élève (admin uniquement)
    """
    queryset = Eleve.objects.filter(actif=True)
    serializer_class = StudentSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        queryset = Eleve.objects.all()
        # Filtrer par classe si fourni
        classe = self.request.query_params.get('classe', None)
        if classe:
            queryset = queryset.filter(classe__nom=classe)
        # Filtrer les actifs par défaut
        actif_only = self.request.query_params.get('actif', 'true')
        if actif_only.lower() == 'true':
            queryset = queryset.filter(actif=True)
        return queryset.order_by('nom', 'prenom')


class AttendanceViewSet(viewsets.ModelViewSet):
    """
    ViewSet pour la gestion des présences.
    POST /api/attendance/ - Enregistrer une présence
    GET /api/attendance/today/ - Liste des présences du jour
    GET /api/attendance/student/:id/ - Historique d'un élève
    """
    queryset = PresenceRepas.objects.all()
    serializer_class = AttendanceSerializer
    permission_classes = [IsAuthenticated]

    @action(detail=False, methods=['get'])
    def today(self, request):
        """Retourne les présences du jour"""
        today = timezone.now().date()
        attendances = PresenceRepas.objects.filter(date=today).select_related('eleve', 'eleve__classe')
        serializer = self.get_serializer(attendances, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'], url_path='student/(?P<student_id>[^/.]+)')
    def student(self, request, student_id=None):
        """Retourne l'historique d'un élève"""
        attendances = PresenceRepas.objects.filter(
            eleve_id=student_id
        ).select_related('eleve', 'eleve__classe').order_by('-date')
        serializer = self.get_serializer(attendances, many=True)
        return Response(serializer.data)

    def create(self, request, *args, **kwargs):
        """Créer ou mettre à jour une présence pour un élève à une date donnée"""
        # Vérifier si une présence existe déjà pour cet élève à cette date
        eleve_id = request.data.get('eleve')
        date_str = request.data.get('date')
        repas = request.data.get('repas', PresenceRepas.TypeRepas.DEJEUNER)
        
        if eleve_id and date_str:
            try:
                existing = PresenceRepas.objects.get(
                    eleve_id=eleve_id,
                    date=date_str,
                    repas=repas
                )
                # Mettre à jour la présence existante
                serializer = self.get_serializer(existing, data=request.data, partial=True)
                serializer.is_valid(raise_exception=True)
                serializer.save()
                return Response(serializer.data, status=status.HTTP_200_OK)
            except PresenceRepas.DoesNotExist:
                pass
        
        # Créer une nouvelle présence
        return super().create(request, *args, **kwargs)


class MenuJournalierViewSet(viewsets.ModelViewSet):
    """API pour les menus journaliers"""
    queryset = MenuJournalier.objects.all()
    serializer_class = MenuJournalierSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        date = self.request.query_params.get('date')
        if date:
            qs = qs.filter(date=date)
        return qs.order_by('-date')


class MenuMensuelViewSet(viewsets.ModelViewSet):
    """API pour les menus mensuels"""
    queryset = MenuMensuel.objects.all()
    serializer_class = MenuMensuelSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = super().get_queryset()
        annee = self.request.query_params.get('annee')
        mois = self.request.query_params.get('mois')
        if annee:
            qs = qs.filter(annee=annee)
        if mois:
            qs = qs.filter(mois=mois)
        return qs.order_by('-annee', '-mois')


class CustomTokenObtainPairView(TokenObtainPairView):
    """Vue personnalisée pour le login avec infos utilisateur"""
    serializer_class = CustomTokenObtainPairSerializer


class CurrentUserView(APIView):
    """Retourne les informations de l'utilisateur connecté"""
    permission_classes = [IsAuthenticated]

    def get(self, request):
        user = request.user
        profile = getattr(user, 'profile', None)
        
        data = {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'first_name': user.first_name or '',
            'last_name': user.last_name or '',
            'role': profile.role if profile else 'prestataire',
            'contact': profile.contact if profile else None,
            'poste': profile.poste if profile else None,
        }
        return Response(data)


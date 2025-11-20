from django.urls import path, include
from django.contrib.auth.views import LogoutView
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    AdminDashboardView,
    ClasseCreateView,
    ClasseDeleteView,
    ClasseListView,
    ClasseUpdateView,
    CustomLoginView,
    DashboardRedirectView,
    DecompteJournalierView,
    DecompteMensuelView,
    DetailPlatsServisView,
    EleveCreateView,
    EleveDeleteView,
    EleveDetailView,
    EleveExportView,
    EleveImportView,
    EleveListView,
    EleveUpdateView,
    ElevesInscritsView,
    GlobalDashboardView,
    MenuCalendarView,
    MenuCreateView,
    MenuDeleteView,
    MenuListView,
    MenuUpdateView,
    PrestataireCreateView,
    PrestataireDashboardView,
    PrestataireDeleteView,
    PrestataireListView,
    PrestataireUpdateView,
    ProfileView,
)
from . import api_views

app_name = "cantine"

# Router pour les vues API
api_router = DefaultRouter()
api_router.register(r'students', api_views.StudentViewSet, basename='student')
api_router.register(r'attendance', api_views.AttendanceViewSet, basename='attendance')
api_router.register(r'menus/journaliers', api_views.MenuJournalierViewSet, basename='menu_journalier')
api_router.register(r'menus/mensuels', api_views.MenuMensuelViewSet, basename='menu_mensuel')

urlpatterns = [
    path("login/", CustomLoginView.as_view(), name="login"),
    path("logout/", LogoutView.as_view(), name="logout"),
    path("dashboard/", DashboardRedirectView.as_view(), name="dashboard_redirect"),
    path("tableau-de-bord/", GlobalDashboardView.as_view(), name="dashboard_overview"),
    path("espace-admin/dashboard/", AdminDashboardView.as_view(), name="admin_dashboard"),
    path("espace-prestataire/dashboard/", PrestataireDashboardView.as_view(), name="prestataire_dashboard"),
    path("profil/", ProfileView.as_view(), name="profile"),
    path("eleves/", EleveListView.as_view(), name="eleve_list"),
    path("eleves/nouveau/", EleveCreateView.as_view(), name="eleve_create"),
    path("eleves/import/", EleveImportView.as_view(), name="eleve_import"),
    path("eleves/export/", EleveExportView.as_view(), name="eleve_export"),
    path("eleves/inscrits/", ElevesInscritsView.as_view(), name="eleves_inscrits"),
    path("eleves/<int:pk>/", EleveDetailView.as_view(), name="eleve_detail"),
    path("eleves/<int:pk>/modifier/", EleveUpdateView.as_view(), name="eleve_update"),
    path("eleves/<int:pk>/supprimer/", EleveDeleteView.as_view(), name="eleve_delete"),
    path("classes/", ClasseListView.as_view(), name="classe_list"),
    path("classes/nouveau/", ClasseCreateView.as_view(), name="classe_create"),
    path("classes/<int:pk>/modifier/", ClasseUpdateView.as_view(), name="classe_update"),
    path("classes/<int:pk>/supprimer/", ClasseDeleteView.as_view(), name="classe_delete"),
    path("menus/", MenuListView.as_view(), name="menu_list"),
    path("menus/nouveau/", MenuCreateView.as_view(), name="menu_create"),
    path("menus/<int:pk>/modifier/", MenuUpdateView.as_view(), name="menu_update"),
    path("menus/<int:pk>/supprimer/", MenuDeleteView.as_view(), name="menu_delete"),
    path("menus/calendrier/", MenuCalendarView.as_view(), name="menu_calendar"),
    path("rapports/decompte-journalier/", DecompteJournalierView.as_view(), name="decompte_journalier"),
    path("rapports/decompte-mensuel/", DecompteMensuelView.as_view(), name="decompte_mensuel"),
    path("rapports/details-plats-servis/", DetailPlatsServisView.as_view(), name="detail_plats_servis"),
    path("prestataires/", PrestataireListView.as_view(), name="prestataire_list"),
    path("prestataires/nouveau/", PrestataireCreateView.as_view(), name="prestataire_create"),
    path("prestataires/<int:pk>/modifier/", PrestataireUpdateView.as_view(), name="prestataire_update"),
    path("prestataires/<int:pk>/supprimer/", PrestataireDeleteView.as_view(), name="prestataire_delete"),
    path("", CustomLoginView.as_view(), name="home"),
    
    # Routes API
    path('api/auth/login/', api_views.CustomTokenObtainPairView.as_view(), name='api_login'),
    path('api/auth/refresh/', TokenRefreshView.as_view(), name='api_refresh'),
    path('api/auth/me/', api_views.CurrentUserView.as_view(), name='api_me'),
    path('api/', include(api_router.urls)),
    path('api-auth/', include('rest_framework.urls'))
]


unit uPrincipal;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.AppEvnts, System.StrUtils;

type
  TFrmPrincipal = class(TForm)
    Panel1: TPanel;
    Timer: TTimer;
    TrayIcon: TTrayIcon;
    GroupBox1: TGroupBox;
    Label1: TLabel;
    Label2: TLabel;
    lbMemTotal: TLabel;
    lbMemUso: TLabel;
    lbMemLivre: TLabel;
    lbTot: TLabel;
    lbUso: TLabel;
    lblivre: TLabel;
    barLivre: TProgressBar;
    barUso: TProgressBar;
    GroupBox2: TGroupBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    barUsoDisco: TProgressBar;
    lbDiskSize: TLabel;
    lbDiskFree: TLabel;
    ApplicationEvents: TApplicationEvents;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure TimerTimer(Sender: TObject);
    procedure ApplicationEventsMinimize(Sender: TObject);
    procedure TrayIconDblClick(Sender: TObject);
  private
    MBTotal: Integer;
    PCUso: Integer;
    MBLivre: Integer;
    PCLivre: Integer;
    MBUso: Integer;
    PCDiscoTotal: Integer;
    PCDiscoLivre: Integer;
    PCDiscoUso  : Integer;
    procedure VerificarMemoria;
    procedure ExibeResultado;
    procedure MontaHint;

    procedure GetGlobalMemoryRecord(var inms: TMemoryStatusEx);
  public
    { Public declarations }
  end;

var
  FrmPrincipal: TFrmPrincipal;

implementation

{$R *.dfm}

{ TMemoryMonitor }

procedure TFrmPrincipal.ApplicationEventsMinimize(Sender: TObject);
begin
  Hide();
  WindowState := wsMinimized;

  TrayIcon.BalloonHint := 'Monitorando memória';
  TrayIcon.Visible := True;
  TrayIcon.Animate := True;
  TrayIcon.ShowBalloonHint;
end;

procedure TFrmPrincipal.ExibeResultado;
begin
  lbTot.Caption      := IntToStr(MBTotal) + ' MB';
  lbUso.Caption      := IntToStr(PCUso) + ' %';
  lbLivre.Caption    := IntToStr(MBLivre) + ' MB';
  barUso.Position    := PCUso;
  barLivre.Position  := PCLivre;

  lbDiskSize.Caption := IntToStr(PCDiscoTotal)+ ' MB';
  lbDiskFree.Caption := IntToStr(PCDiscoLivre)+ ' MB';
  barUsoDisco.Position := PCDiscoUso;

  if PCDiscoUso >= 90 then
  begin
    barUsoDisco.State := pbsError;
    TrayIcon.BalloonHint := 'Alto consumo da memória RAM!';
    TrayIcon.ShowBalloonHint;
  end
  else
    barUsoDisco.State := pbsNormal;

  if PCUso >= 90 then
    barUso.State := pbsError
  else
    barUso.State := pbsNormal;

  if PCLivre >= 90 then
  begin
    barLivre.State := pbsError;
    TrayIcon.BalloonHint := 'Disco quase cheio!';
    TrayIcon.ShowBalloonHint;
  end
  else
    barLivre.State := pbsNormal;
end;

procedure TFrmPrincipal.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TFrmPrincipal.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_Escape then
    Self.Close;
end;

procedure TFrmPrincipal.GetGlobalMemoryRecord(var inms: TMemoryStatusEx);
type
  TGlobalMemoryStatusEx = procedure(var lpBuffer: TMemoryStatusEx); stdcall;
var
  ms : TMemoryStatus;
  h : THandle;
  gms : TGlobalMemoryStatusEx;
begin
  h := LoadLibrary('kernel32.dll');
  try
    if h <> 0 then
      begin
        @gms := GetProcAddress(h, 'GlobalMemoryStatusEx');
        if @gms <> nil then
          begin
            inms.dwLength := sizeof(inms);
            gms(inms)
          end
        else
          begin
            Ms.dwLength := sizeof(Ms);
            GlobalMemoryStatus(Ms);
            inms.dwMemoryLoad := ms.dwMemoryLoad;
            inms.ullTotalPhys := ms.dwTotalPhys;
            inms.ullAvailPhys := ms.dwAvailPhys;
            inms.ullTotalPageFile := ms.dwTotalPageFile;
            inms.ullAvailPageFile := ms.dwAvailPageFile;
            inms.ullTotalVirtual := ms.dwTotalVirtual;
            inms.ullAvailVirtual := ms.dwAvailVirtual;
          end;
      end;
  finally
    FreeLibrary(h);
  end;
end;

procedure TFrmPrincipal.MontaHint;
begin
  TrayIcon.BalloonHint :=
    lbMemTotal.Caption + lbTot.Caption + sLineBreak +
    lbMemLivre.Caption + lblivre.Caption + sLineBreak +
    lbMemUso.Caption + lbUso.Caption + sLineBreak +
    ifthen(PCLivre >= 90, 'Alto consumo de memória', 'Consumo normal');

  TrayIcon.Visible := True;
  TrayIcon.Animate := True;
end;

procedure TFrmPrincipal.TimerTimer(Sender: TObject);
begin
  VerificarMemoria;
  ExibeResultado;
  MontaHint;
end;

procedure TFrmPrincipal.TrayIconDblClick(Sender: TObject);
begin
  TrayIcon.Visible := False;
  Show();
  WindowState := wsNormal;
  Application.BringToFront();
end;

procedure TFrmPrincipal.VerificarMemoria;
var
  mstatus: TMemoryStatusEx;
begin
  mstatus.dwLength := sizeof(MemoryStatus);
  GetGlobalMemoryRecord(mstatus);

  PCUso   := (mstatus.dwMemoryLoad);
  PCLivre := 100 - PCUso;
  MBTotal := ((mstatus.ullTotalPhys div 1024) div 1024) + 1;
  MBLivre := ((mstatus.ullAvailPhys div 1024) div 1024) + 1;
  MBUso   := MBTotal - MBLivre;
  PCDiscoTotal := ((DiskSize(0) div 1024) div 1024) + 1;
  PCDiscoLivre := ((DiskFree(0) div 1024) div 1024) + 1;
  PCDiscoUso   := Round(((PCDiscoTotal - PCDiscoLivre) *100) / PCDiscoTotal);
end;

end.

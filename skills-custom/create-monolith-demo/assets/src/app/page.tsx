export default function HomePage() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-6">
      <h1 className="text-4xl font-bold tracking-tight">
        {"{{PROJECT_NAME}}"}
      </h1>
      <p className="mt-4 text-muted-foreground">
        프로젝트가 성공적으로 생성되었습니다. 구현을 시작하세요.
      </p>
    </main>
  );
}
